/****************************************
NHS Tariff Project - Kubrick Group
Chad Meadowcroft 02/2019
****************************************/
USE nhstariff
GO

-- DROP OBJECTS IF EXISTING --
IF OBJECT_ID(N'dbo.usp_tariffs18') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.usp_tariffs18
END
GO

IF OBJECT_ID(N'dbo.FINALTariff18') IS NOT NULL
BEGIN
	DROP TABLE dbo.FINALTariff18
END
GO

IF TYPE_ID(N'dbo.HesTableType18') IS NOT NULL
BEGIN
	DROP TYPE dbo.HesTableType18
END
GO

-- CREATE TYPE FOR TVP --
CREATE TYPE dbo.HesTableType18 AS TABLE( 
	 EpisodeID BIGINT NOT NULL
	,newnhsno VARCHAR(50)  
	,spell INT
	,episode INT
	,epidur INT
	,diag VARCHAR(10)
	,HRG VARCHAR(10)
	,classpat INT
	,admimeth VARCHAR(10)
)
GO  

-- CREATE PROCEDURE TO GENERATE TARIFFS --
CREATE PROCEDURE dbo.usp_tariffs18
	@TVP HesTableType18 READONLY
	AS
	SET NOCOUNT ON
	CREATE TABLE FINALTariff18(EpisodeID INT, NHSNo VARCHAR(50), Spell INT, Episode INT, Epidur INT, Diag VARCHAR(10), HRG VARCHAR(20), Tariff MONEY)

	INSERT INTO FINALTariff18(EpisodeID, NHSNo, Spell, Episode, Epidur, Diag, HRG, Tariff)
	SELECT
		 EpisodeID
		,newnhsno
		,spell
		,episode
		,EPIDUR
		,diag
		,HRG
		,CASE
			WHEN EPIDUR <2 AND [emergency_t] IS NOT NULL THEN CAST([emergency_t] AS MONEY)
			WHEN [EPIDUR] > [trim] THEN CAST((([EPIDUR] - [trim]) * [longstay_t]) + CAST([base_price] AS INT) AS MONEY)
			ELSE CAST([base_price] AS MONEY)
		END
	FROM
	(
        -- GET PRICE & TRIM DAYS FOR CATEGORIES
		SELECT
			 EpisodeID
			,newnhsno
			,spell
			,episode
			,EPIDUR
			,diag
			,HRG
			,CASE
				WHEN cat = 'outpatient' THEN CAST(REPLACE([outpatient_t],',','') AS INT)
				WHEN cat = 'day-case' THEN 
					CASE 
						WHEN [daycase_t] IS NOT NULL THEN CAST(REPLACE([daycase_t],',','') AS INT)
						ELSE CAST(REPLACE([comb_t],',','') AS INT)
					END
				WHEN cat = 'elective' THEN
					CASE 
						WHEN [elective_t] IS NOT NULL THEN CAST(REPLACE([elective_t],',','') AS INT)
						ELSE CAST(REPLACE([comb_t],',','') AS INT)
					END
				WHEN cat = 'non-elective' THEN [non-elective_t]
			 END AS base_price
			,CASE
				WHEN cat = 'elective' THEN [elective_trim]
				WHEN cat = 'non-elective' THEN [non-elective_trim]
			 END AS trim
			,[longstay_t]
			,[emergency_t]
		FROM 
		(
			SELECT 
				 g.EpisodeID AS EpisodeID
				,g.newnhsno
				,g.spell
				,g.episode
				,CAST(g.[EPIDUR] AS INT) AS EPIDUR
				,g.diag
				,g.HRG AS HRG
				,CASE 
					WHEN apc.[HRG name] IS NOT NULL THEN apc.[HRG name]
					WHEN apc.[HRG name] IS NULL AND nop.[HRG name] IS NOT NULL THEN nop.[HRG name]
					WHEN apc.[HRG name] IS NULL AND nop.[HRG name] IS NULL AND ae.[HRG name] IS NOT NULL THEN ae.[HRG name]
					WHEN apc.[HRG name] IS NULL AND nop.[HRG name] IS NULL AND ae.[HRG name] IS NULL AND mat.[HRG name] IS NOT NULL THEN mat.[HRG name]
				 END AS HRG_name
				,NULLIF(apc.[Outpatient procedure tariff (£)], '-') AS [outpatient_t]
				,CASE 
					WHEN apc.[Combined day case / ordinary elective spell tariff (£)] IS NOT NULL THEN apc.[Combined day case / ordinary elective spell tariff (£)]
					WHEN apc.[Combined day case / ordinary elective spell tariff (£)] IS NULL AND nop.[HRG with no national price across all settings?] = 'Y' THEN 0
					WHEN apc.[Combined day case / ordinary elective spell tariff (£)] IS NULL AND nop.[HRG with no national price across all settings?] IS NULL AND ae.[Type 1 and 2 Departments] IS NOT NULL THEN ae.[Type 1 and 2 Departments]
					WHEN apc.[Combined day case / ordinary elective spell tariff (£)] IS NULL AND nop.[HRG with no national price across all settings?] IS NULL AND ae.[Type 1 and 2 Departments] IS NULL AND mat.[Combined day case / ordinary elective spell tariff (£)] IS NOT NULL THEN mat.[Combined day case / ordinary elective spell tariff (£)]
				 END AS [comb_t]
				,CASE
					WHEN NULLIF(apc.[Day case spell tariff (£)], '-') IS NOT NULL THEN apc.[Day case spell tariff (£)]
					WHEN NULLIF(apc.[Day case spell tariff (£)], '-') IS NULL AND NULLIF(mat.[Day case spell tariff (£)], '-') IS NOT NULL THEN mat.[Day case spell tariff (£)]
					ELSE NULL
				 END AS [daycase_t]
				,CASE
					WHEN NULLIF(apc.[Ordinary elective spell tariff (£)], '-') IS NOT NULL THEN apc.[Ordinary elective spell tariff (£)]
					WHEN NULLIF(apc.[Ordinary elective spell tariff (£)], '-') IS NULL AND NULLIF(mat.[Ordinary elective spell tariff (£)], '-') IS NOT NULL THEN mat.[Ordinary elective spell tariff (£)]
					ELSE NULL
				 END AS [elective_t]
				,CASE	
					WHEN apc.[Non-elective spell tariff (£)] IS NOT NULL THEN apc.[Non-elective spell tariff (£)]
					WHEN apc.[Non-elective spell tariff (£)] IS NULL AND mat.[Non-elective spell tariff (£)] IS NOT NULL THEN mat.[Non-elective spell tariff (£)]
				 END AS [non-elective_t]
				,CASE 
					WHEN apc.[Ordinary elective long stay trim point (days)] IS NOT NULL THEN apc.[Ordinary elective long stay trim point (days)]
					WHEN apc.[Ordinary elective long stay trim point (days)] IS NULL AND mat.[Ordinary elective long stay trim point (days)] IS NOT NULL THEN mat.[Ordinary elective long stay trim point (days)]
				 END AS [elective_trim]
				,CASE 
					WHEN apc.[Non-elective long stay trim point (days)] IS NOT NULL THEN apc.[Non-elective long stay trim point (days)] 
					WHEN apc.[Non-elective long stay trim point (days)] IS NULL AND mat.[Non-elective long stay trim point (days)] IS NOT NULL THEN mat.[Non-elective long stay trim point (days)]
				 END AS [non-elective_trim]
				,CASE 
					WHEN apc.[Per day long stay payment (for days exceeding trim point) (£)] IS NOT NULL THEN apc.[Per day long stay payment (for days exceeding trim point) (£)] 
					WHEN apc.[Per day long stay payment (for days exceeding trim point) (£)] IS NULL AND mat.[Per day long stay payment (for days exceeding trim point) (£)] IS NOT NULL THEN mat.[Per day long stay payment (for days exceeding trim point) (£)]
				 END AS [longstay_t]
				,apc.[Reduced short stay emergency tariff (£)] AS [emergency_t]
				,CASE
					WHEN CAST(EPIDUR AS INT) = 0 THEN
						CASE
							WHEN CLASSPAT = '3' THEN 'outpatient'
							WHEN CLASSPAT = '2' THEN 'day-case'
							WHEN CLASSPAT = '1' THEN
								CASE 
									WHEN NULLIF(apc.[Outpatient procedure tariff (£)], '-') IS NOT NULL THEN 'outpatient'
									ELSE 'day-case'
								END
							END
					WHEN CAST(EPIDUR AS INT) > 0 THEN
						CASE
							WHEN ADMIMETH IN ('11', '12', '13') THEN 'elective'
							WHEN ADMIMETH IN ('21', '22', '23', '24', '25','2A', '2B', '2C', '2D', '28', '31', '32', '81', '82', '83') THEN 'non-elective'
						END
					ELSE 'NA'
					END AS cat
			FROM @TVP g
			LEFT JOIN stage.apc18 apc
				ON g.HRG = apc.[HRG code]
			LEFT JOIN stage.noprice nop
				ON g.HRG = nop.[HRG code]
			LEFT JOIN stage.AE18 ae
				ON g.HRG = ae.[HRG code]
			LEFT JOIN stage.maternity18 mat
				ON g.HRG = mat.[HRG code]
		) t
) tt
GO

-- CREATE TVP & INSERT HES DATA --
DECLARE @HESTVP AS HesTableType18
INSERT INTO @HESTVP(EpisodeID, newnhsno, spell, episode, epidur, diag, HRG, classpat, admimeth)  
    SELECT 
		 EpisodeID
		,newnhsno
		,CAST(spell AS INT)
		,CAST(episode AS INT)
		,CAST(epidur AS INT)
		,diag_01
		,HRG_code
		,CAST(classpat AS INT)
		,admimeth
    FROM dbo.HES  --<--< CHANGE THIS TO CHANGE INPUT DATA
EXEC dbo.usp_tariffs18 @HESTVP
GO

-- READ DATA --
SELECT * FROM FINALTariff18
ORDER BY EpisodeID