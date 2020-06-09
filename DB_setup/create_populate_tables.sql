create schema bolt
;

create table bolt.hourly_overview_search
(
	date_original char(13)
	,date_parsed timestamp
	,people_saw_0_cars_uniq integer
	,people_saw_1more_cars_uniq integer
	,coverage_ratio_uniq integer
)
;


create table bolt.hourly_driver_activity
(
	date_original char(13)
	,date_parsed timestamp
	,active_drivers integer
	,online_h integer
	,has_booking_h integer
	,waiting_for_booking_h integer
	,busy_h integer
	,hours_per_active_driver numeric (5,2)
	,rides_per_online_hour numeric (5,2)
	,finished_rides integer
)
;


COPY bolt.hourly_overview_search(date_original, people_saw_0_cars_uniq, people_saw_1more_cars_uniq, coverage_ratio_uniq) 
FROM '/Hourly_OverviewSearch.csv' DELIMITER ',' CSV HEADER
;


update bolt.hourly_overview_search
set date_parsed = to_timestamp(concat(date_original, ':00:00'), 'YYYY-MM-DD HH24:MI:SS')
;


select *
from bolt.hourly_overview_search
;


COPY bolt.hourly_driver_activity(date_original
								 ,active_drivers
								 ,online_h 
								,has_booking_h 
								,waiting_for_booking_h 
								,busy_h 
								,hours_per_active_driver 
								,rides_per_online_hour 
								,finished_rides
								) 
FROM '/Hourly_DriverActivity.csv' DELIMITER ',' CSV HEADER
;

update bolt.hourly_driver_activity
set date_parsed = to_timestamp(concat(date_original, ':00:00'), 'YYYY-MM-DD HH24:MI:SS')
;


select *
from bolt.hourly_driver_activity
;


