# NHS-Tariff-Project  
SQL code to create and execute stored procedures which give NHS tariff costs by hospital episode.  

## Files  
- createTables.sql - Cleans tariff, episode, & admissions tables, prepares for procedures  
- Proc2018.sql - Outputs 2018 NHS tariffs by episode from a supplied episode table  
- Proc2019.sql - Outputs 2019 NHS tariffs by episode from a supplied episode table  

## Data  
- NHS Tariffs 2017/18 & 2018/19: https://improvement.nhs.uk/resources/national-tariff-1719/  
- HRG Grouper tool: https://digital.nhs.uk/services/national-casemix-office/downloads-groupers-and-tools/payment-hrg4-2017-18-local-payment-grouper  
- Hospital activity: https://www.england.nhs.uk/statistics/statistical-work-areas/hospital-activity/quarterly-hospital-activity/qar-data/  

## Useage
1. Batch process episode data using HRG Grouper to obtain HRG codes for each. The required fields for the episode data are procodet, epiorder, startage, sex, classpat, admisorc, admimeth, disdest, dismeth, epidur, mainspef, neocare, tretspef, & diag_01  
2. Import the "XX_FCE.CSV" output file into SQL as stage.HES, 2018/19 admitted patient tariffs as stage.apc18 and 2018/19 as stage.apc19. The admissions data is non-essential.  
3. Run createTables.sql to create dbo.HES, dbo.apc18, & dbo.apc19  
4. Run Proc2018.sql and Proc2019.sql to create dbo.FINALTariff18 and dbo.FINALTariff19 respectively  