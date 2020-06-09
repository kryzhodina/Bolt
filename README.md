## Bolt
###### Supply/Demand Analytics Home Assignment

Repository includes files:
  - files to set up table and populate it
  - SQL query solution compatible with PostgreSQL [Iryna_Kuzmiankova_suuply_demand_analysis.sql](Iryna_Kuzmiankova_suuply_demand_analysis.sql).
  - Tableau dashboard with the story line (open with Tableau Reader/or Desktop: [Iryna_Kuzmiankova_Bolt_SupplyDemand_Analysis.twbx](Iryna_Kuzmiankova_Bolt_SupplyDemand_Analysis.twbx), or follow the link to view the same solution on Tableau Public:
  https://public.tableau.com/profile/iryna.kuzmiankova3251#!/vizhome/Bolt_Supply_Demand_Home_Assignment/SupplyDemanddynamics
  )
  
To review the SQL solution from the [Iryna_Kuzmiankova_suuply_demand_analysis.sql](Iryna_Kuzmiankova_suuply_demand_analysis.sql), please proceed with the following steps:

- run Docker container using the following command:

`docker run --rm --name postgres -e POSTGRES_USER="root" -e POSTGRES_PASSWORD="toor" -e POSTGRES_DB="tableau" -p 5432:5432 postgres:9.6.17-alpine`

- log in to the created database with the credentials:
    * host: 127.0.0.1
    * port: 5432
    * database: tableau
    * user: root
    * password: toor
    
- copy Hourly_DriverActivity.csv and Hourly_OverviewSearch.csv files to the root directory of the container.
- run the script named [create_populate_tables.sql](create_populate_tables.sql) to create appropriate schema and table, and populate it with data.
- run the script named [create_date_dimension.sql](create_date_dimension.sql) to create auxiliary date dimension.
- review the solution from [Iryna_Kuzmiankova_suuply_demand_analysis.sql](Iryna_Kuzmiankova_suuply_demand_analysis.sql) file.

After shutting down the docker process the container will be automatically removed.
