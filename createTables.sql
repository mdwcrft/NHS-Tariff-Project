USE nhstariff
GO


/****************************************
NHS Tariff Project - Kubrick Group
Chad Meadowcroft 02/2019
****************************************/
GO

-- CLEAN HES TABLE ----
IF OBJECT_ID(N'dbo.HES') IS NOT NULL
BEGIN
	DROP TABLE dbo.HES
END
GO

SELECT
	 IDENTITY(INT, 1, 1) AS EpisodeID
	--,IDENTITY(INT, 1, @epsinspell) AS SpellID
	,spell
	,episode
	,epidur
	,sex
	,admiage
	,admimeth
	,classpat
	,newnhsno
	,diag_01
	,HRG_code
INTO dbo.HES
FROM stage.HES
GO


------ PREFIX COLUMNS WITH YEAR NO. & FORMAT -----------------
IF OBJECT_ID(N'dbo.apc18') IS NOT NULL
BEGIN
	DROP TABLE dbo.apc18
END
GO

SELECT [HRG code] AS [18Code]                                                           
      ,[HRG name] AS [18Name]
      ,CAST(REPLACE(NULLIF([Outpatient procedure tariff (£)], '-'),',','') AS INT) AS [18OutpatientTariff]
      ,ISNULL([Combined day case / ordinary elective spell tariff (£)], CAST(REPLACE(NULLIF([Day case spell tariff (£)], '-'),',','') AS INT) + CAST(REPLACE(NULLIF([Ordinary elective spell tariff (£)], '-'), ',','') AS INT)) AS [18CombinedTariff]
      ,CAST(REPLACE(NULLIF([Day case spell tariff (£)], '-'),',','') AS INT) AS [18DayCaseTariff]
      ,CAST(REPLACE(NULLIF([Ordinary elective spell tariff (£)], '-'), ',','') AS INT) AS [18ElectiveTariff]
      ,[Ordinary elective long stay trim point (days)] AS [18ElectiveTrim]
      ,[Non-elective spell tariff (£)] AS [18NonElectiveTariff]
      ,[Non-elective long stay trim point (days)] AS [18NonElectiveTrim]
      ,[Per day long stay payment (for days exceeding trim point) (£)] AS [18LongStayTariff]
      ,[% applied in calculation of reduced short stay emergency tariff ] AS [18ShortStayPer]
      ,[Reduced short stay emergency tariff (£)] AS [18ShortStayTariff]
INTO dbo.apc18
FROM [stage].[apc18]
GO

IF OBJECT_ID(N'dbo.apc19') IS NOT NULL
BEGIN
	DROP TABLE dbo.apc19
END
GO

SELECT [HRG code] AS [19Code]                                                           
      ,[HRG name] AS [19Name]
      ,CAST(REPLACE(NULLIF([Outpatient procedure tariff (£)], '-'),',','') AS INT) AS [19OutpatientTariff]
      ,ISNULL([Combined day case / ordinary elective spell tariff (£)], CAST(REPLACE(NULLIF([Day case spell tariff (£)], '-'),',','') AS INT) + CAST(REPLACE(NULLIF([Ordinary elective spell tariff (£)], '-'), ',','') AS INT)) AS [19CombinedTariff]
      ,CAST(REPLACE(NULLIF([Day case spell tariff (£)], '-'),',','') AS INT) AS [19DayCaseTariff]
      ,CAST(REPLACE(NULLIF([Ordinary elective spell tariff (£)], '-'), ',','') AS INT) AS [19ElectiveTariff]
      ,[Ordinary elective long stay trim point (days)] AS [19ElectiveTrim]
      ,[Non-elective spell tariff (£)] AS [19NonElectiveTariff]
      ,[Non-elective long stay trim point (days)] AS [19NonElectiveTrim]
      ,[Per day long stay payment (for days exceeding trim point) (£)] AS [19LongStayTariff]
      ,[% applied in calculation of reduced short stay emergency tariff ] AS [19ShortStayPer]
      ,[Reduced short stay emergency tariff (£)] AS [19ShortStayTariff]
INTO dbo.apc19
FROM [stage].[apc19]
GO


-- JOIN BOTH YEARS & HRG CODES TO SINGLE TABLE --------------------
SELECT *
INTO dbo.FACT
FROM dbo.apc18 a
INNER JOIN dbo.apc19 b
	ON a.[18Code] = b.[19Code]
INNER JOIN stage.hrgcats h
	ON LEFT(a.[18code], 2) = h.[HRG Subchapter]



------ CREATE TABLE OF ADMISSIONS BY AREA --------
IF OBJECT_ID(N'dbo.Admissions') IS NOT NULL
BEGIN
	DROP TABLE dbo.Admissions
END
GO

SELECT
       ad.[Provider Parent name]
	  ,ar.Organisation
      ,ad.[Provider Org name]
	  ,ad.[Provider Parent org code]
      ,ad.[Commissioner Org Name]
	  ,ar.[Commissioning Region Name]
      ,CAST([Ip Elect Total] AS INT) + CAST([Ip Electotal Planned] AS INT) + CAST([Ip Nonelect] AS INT) AS [Inpatients]
      ,CAST([Op Gprefsmade M] AS INT) + CAST([Op Gprefsmade Ga M] AS INT) + CAST([Op Otherrefsmade Ga M] AS INT) AS [OutpatientRefs]
	  ,ISNULL(ar.Area, ar.F10) AS [area]
	  ,ISNULL(ar.[Post Code], ar.F11) AS [PostCode]
into dbo.Admissions
FROM [stage].[AdmissionsMar18] ad
INNER JOIN stage.nhsAreas ar
	ON ad.[Provider Org code] = ar.Code
GO