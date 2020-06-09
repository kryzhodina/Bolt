/* Supply/Demand analysis SQL-implemeted */

/* Task 1. Show which 36 hours in a week are most undersupplied.

Undersupplied hours are identified as hours with the lowest coverage ratio.
As ratio of saw_0_customers to saw_1+_customers shows when company failed to deliver adequate number of drivers.
Average metric is chosen since it gives better central tendency on small datasets.

*/
 
select dd.day_name
		,extract(hour from ovrw.date_parsed) as hour_parsed
		,round(avg(coverage_ratio_uniq),0) as avg_coverage_ratio
from bolt.hourly_overview_search ovrw
	join bolt.d_date dd
		on date(ovrw.date_parsed) = dd.date_actual
group by dd.day_name
		,extract(hour from ovrw.date_parsed)
order by round(avg(coverage_ratio_uniq),0) asc
limit 36
;


/* Task 2. 24-hour curve of average supply and demand (to illustrate match/mismatch). - visualized in Tableau */

/* Task 3. Visualisation of hours where we lack supply during a weekly period. - visualized in Tableau */

/* Task 4. Estimate number of hours needed to ensure we have a high Coverage Ratio during most peak hours.
	Peak hours are defined as hours with the highest number of customers' attempts to set pickup marker (= highest demand).
	Number of hours that would be sufficient to cover customers who didn't see a car is calculated as following: 
		Estimated Hours to Cut Undersupply = People Saw 0 Cars * Online Hrs by 1 Customer.
	Estimated fraction of online hours per customer for previous calculation: 
		Online Hrs by 1 Customer = Online Hours / People Saw +1 Cars. 
*/

select day_name
		,hour_parsed
		,estimated_hrs_to_cut_undersupply
from
(select dd.day_name
 		,dd.day_of_week_iso
		,extract(hour from drvr.date_parsed) as hour_parsed
		,round(avg(ovrw.people_saw_0_cars_uniq + ovrw.people_saw_1more_cars_uniq),0) as avg_demand /* estimate average demand = all people who set a pickup marker */
		,round(avg(online_h),0) as avg_online_h
		,round(avg(people_saw_1more_cars_uniq),0) as avg_people_saw_1more_cars
		,round(avg(online_h)/avg(people_saw_1more_cars_uniq),2) as online_hrs_by_1_cust /* estimate fraction of online hours per customer */
		,round((avg(online_h)/avg(people_saw_1more_cars_uniq)) * avg(people_saw_0_cars_uniq),0) as estimated_hrs_to_cut_undersupply /* estimate hours needed to cover undersupplied customers */
from bolt.hourly_driver_activity drvr
 	/* left join is used to account for lacking hours from hourly_overview_search compared to hourly_driver_activity */
	left join bolt.hourly_overview_search ovrw 
		on drvr.date_parsed = ovrw.date_parsed
	join bolt.d_date dd
		on date(drvr.date_parsed) = dd.date_actual
group by dd.day_name
 		,dd.day_of_week_iso
		,extract(hour from drvr.date_parsed)
/* get 36 hours with the highest demand */
order by avg(ovrw.people_saw_0_cars_uniq + ovrw.people_saw_1more_cars_uniq) desc 
limit 36 
) src
order by day_of_week_iso
		,hour_parsed
;

/* Task 5. Calculate levels of guaranteed hourly earnings we can offer to drivers during 36 weekly hours with highest demand without losing money
			+ how much extra hours we want to get to capture missed demand.
			
	Note:
		General idea behind the solution was to estimate how much driver would earn anyway, if he/she will be online in peak hours. In order to achieve it,
		RPH corrected by estimated demand was calculated, based on assumptions of missed hours, which in turn were derived from estimated missed customers.
		Estimated Hrs to cut Undersupply from the previous task are slightly different from Missed Hours, used to calculate Hourly Earnings. 
		Missed Hours in that case are corrected by Demand Coefficient. Meaning, in reality not all customers who set pickup marker and saw a car,
		will proceed to making an order. Thus, the real driver earning is less than it could be expected from all the 'missed' customers.
		The aim of this correction is to ensure Bolt won't lose money.
	
	Calculations: 
	Hourly Earnings = corrected RPH averaged by 3 hours * 10 * 0.8
	Corrected RPH = (Missed Trips + Finished Trips)/(Online Hrs + Missed Hours)
	Online Hrs by 1 customer = Online Hours/People saw +1 cars
	Missed Hours = Online Hrs by 1 customer * Missed Customers
	Missed Customers = People saw 0 cars * Demand Correction Coefficient
	Demand Correction Coefficient = Finished Trips / People saw 1+ cars

*/

select fin.day_name	
		,fin.hour_parsed
		,round(fin.missed_hours,0) as estimated_hours_to_cut_undersupply
		,fin.driver_hrly_rate_corrected as driver_hourly_rate
from
(
	select src.day_name
			,src.day_of_week_iso
			,src.hour_parsed
			,src.missed_hours
			,src.avg_demand
			,(src.finished_rides_adj + missed_trips)/(avg_online_h + missed_hours) as corrected_rph
			/* RPH averaged by 3 hour window */
			,round(avg(round((src.finished_rides_adj + missed_trips)/(avg_online_h + missed_hours),2))
				over(order by src.day_of_week_iso,src.hour_parsed rows between 1 preceding and 1 following),2) as corrected_rph_3hrs_wind
			/* RPH averaged by 3 hr window * average trip cost * average part of a cost that goes to driver */
			,round(round(avg(round((src.finished_rides_adj + missed_trips)/(avg_online_h + missed_hours),2))
				over(order by src.day_of_week_iso,src.hour_parsed rows between 1 preceding and 1 following),2) * 10 * 0.8,0) as driver_hrly_rate_corrected
	from
	(
		select dd.day_name
 			,dd.day_of_week_iso
			,extract(hour from drvr.date_parsed) as hour_parsed
			,avg(ovrw.people_saw_0_cars_uniq + ovrw.people_saw_1more_cars_uniq) as avg_demand
			,avg(online_h)/avg(people_saw_1more_cars_uniq) as online_hrs_by_1_cust
			,avg(coalesce(drvr.finished_rides,0)) as finished_rides_adj /* null values are substituted by 0, since absence of the ride means 0 rides were performed */
			,avg(coalesce(drvr.finished_rides,0))/avg(ovrw.people_saw_1more_cars_uniq) as demand_correcting_coefficient /* estimate of customers who not only set a pickup marker, but proceeded with a ride*/
			/* people saw 0 cars * demand correcting coefficient */
			,avg(people_saw_0_cars_uniq) * 
				avg(coalesce(drvr.finished_rides,0))/avg(ovrw.people_saw_1more_cars_uniq) as missed_customers
			/* online hour by 1 customer * missed customers  */
			,avg(online_h)/avg(people_saw_1more_cars_uniq) * 
				(avg(people_saw_0_cars_uniq) * 
				avg(coalesce(drvr.finished_rides,0))/avg(ovrw.people_saw_1more_cars_uniq)) as missed_hours
			,avg(online_h) as avg_online_h
			/* estimated fraction of booking hours dedicated for a trip */
			,avg(has_booking_h)/avg(coalesce(drvr.finished_rides,0)) as trip_length
			/* missed hours * trip length */
 			,coalesce(avg(online_h)/avg(people_saw_1more_cars_uniq) * 
				(avg(people_saw_0_cars_uniq) * 
				avg(coalesce(drvr.finished_rides,0))/avg(ovrw.people_saw_1more_cars_uniq)) 
 		 	/  nullif(avg(has_booking_h)/avg(coalesce(drvr.finished_rides,0)),0),0) as missed_trips /* nullif function is used to avoid division by zero in case of absent rides */
	from bolt.hourly_driver_activity drvr
		/* left join is used to account for lacking hours from hourly_overview_search compared to hourly_driver_activity */
		left join bolt.hourly_overview_search ovrw
			on drvr.date_parsed = ovrw.date_parsed
		join bolt.d_date dd
			on date(drvr.date_parsed) = dd.date_actual
	group by dd.day_name
 		,dd.day_of_week_iso
		,extract(hour from drvr.date_parsed)
	) src
	/* get 36 hours with highest demand */
	order by src.avg_demand desc
	limit 36
	) fin
order by day_of_week_iso
		,hour_parsed
;


