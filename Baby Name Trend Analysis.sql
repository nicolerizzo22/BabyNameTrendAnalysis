-- BABY NAME TREND ANALYSIS

-- Objective #1 - TRACK CHANGES IN POPULARITY
-- 1. Find the overall most popular girl name and most popular boy name. 
-- Show how they changed in popularity rankings over the years. 

USE baby_names_db;
SELECT * FROM names;

-- 1. Find the overall most popular girl name
SELECT Name, SUM(births) as num_babies
FROM names
WHERE Gender = 'F'
GROUP BY Name
ORDER BY num_babies DESC
LIMIT 1; -- jessica at 863,121 


-- 2. Find the overall most popular boy name
SELECT Name, SUM(births) as num_babies
FROM names
WHERE Gender = 'M'
GROUP BY Name
ORDER BY num_babies DESC
LIMIT 1; --michael at 1,376,418



-- Queries to find ranking change over the years. Save previous output as CTE.
SELECT * FROM
(WITH girl_names AS (SELECT Year, Name, SUM(Births) as num_babies
FROM names
WHERE Gender = 'F'
GROUP BY Year, Name)

SELECT Year, Name,
      ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
FROM girl_names) AS popular_girl_names
WHERE Name = 'Jessica';

-- Copy and paste changing to boy search for Michael
SELECT * FROM
(WITH boy_names AS (SELECT Year, Name, SUM(Births) as num_babies
FROM names
WHERE Gender = 'M'
GROUP BY Year, Name)

SELECT Year, Name,
      ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
FROM boy_names) AS popular_boy_names
WHERE Name = 'Michael';



-- 2. Find the names with the biggest jumps in popularity from the first year of 
--    the data set to the last year of the data set
WITH names_1980 AS (
	WITH all_names AS (SELECT Year, Name, SUM(Births) AS num_babies
	FROM names
	GROUP BY Year, Name)

	SELECT Year, Name,
	ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
	FROM all_names
	WHERE Year = 1980),
    
    names_2009 AS (
    WITH all_names AS (SELECT Year, Name, SUM(Births) AS num_babies
	FROM names
	GROUP BY Year, Name)

	SELECT Year, Name,
	ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
	FROM all_names
	WHERE Year = 2009)
    
    SELECT *
    FROM names_2009;
    
    -- Join the tables together so that the 1980 rankings table 
    -- and the 2009 rankings table are next to each other. 
    
    WITH names_1980 AS (
	WITH all_names AS (SELECT Year, Name, SUM(Births) AS num_babies
	FROM names
	GROUP BY Year, Name)

	SELECT Year, Name,
	ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
	FROM all_names
	WHERE Year = 1980),
    
    names_2009 AS (
    WITH all_names AS (SELECT Year, Name, SUM(Births) AS num_babies
	FROM names
	GROUP BY Year, Name)

	SELECT Year, Name,
	ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
	FROM all_names
	WHERE Year = 2009)
    
    SELECT *
    FROM names_1980 t1 INNER JOIN names_2009 t2
		ON t1.Name = t2.Name;


        
-- After the inner join, to get the biggest jump in rankings, 
-- we'll subtract the popularity from table 1 (1980) from the popularity in table 2 (2009).
   
   WITH names_1980 AS (
	WITH all_names AS (SELECT Year, Name, SUM(Births) AS num_babies
	FROM names
	GROUP BY Year, Name)

	SELECT Year, Name,
	ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
	FROM all_names
	WHERE Year = 1980),
    
    names_2009 AS (
    WITH all_names AS (SELECT Year, Name, SUM(Births) AS num_babies
	FROM names
	GROUP BY Year, Name)

	SELECT Year, Name,
	ROW_NUMBER() OVER (PARTITION BY Year ORDER BY num_babies DESC) AS popularity
	FROM all_names
	WHERE Year = 2009)
    
    SELECT t1.Year, t1.Name, t1.popularity, t2.Year, t2.Name, t2.popularity,
		CAST(t2.popularity AS SIGNED) - CAST(t1.popularity as SIGNED) AS diff
    FROM names_1980 t1 INNER JOIN names_2009 t2
		ON t1.Name = t2.Name
        ORDER BY diff;
        
-- Objective 2 - COMPARE POPULARITY ACROSS DECADES
-- For each year and each decade, return the 3 most popular girl and 3 most popular boy names. 

WITH babies_by_year AS 
		(SELECT Year, Gender, Name, SUM(births) AS num_babies
		FROM names
		GROUP BY Year, Gender, Name)
SELECT Year, Gender, Name, num_babies,
	ROW_NUMBER() OVER (PARTITION BY Year, Gender ORDER BY num_babies DESC) AS popularity
FROM babies_by_year;

-- In order to get only the top 3 for each year, boy & girl,  
-- make the previous query a sub-query and put a constraint on the output.

SELECT * FROM
(WITH babies_by_year AS 
		(SELECT Year, Gender, Name, SUM(births) AS num_babies
		FROM names
		GROUP BY Year, Gender, Name)
SELECT Year, Gender, Name, num_babies,
	ROW_NUMBER() OVER (PARTITION BY Year, Gender ORDER BY num_babies DESC) AS popularity
FROM babies_by_year) AS top_three
WHERE popularity < 4;
 
-- Now check the top 3 names (boy & girl) for each decade. 
-- Combine the years into decades with a CASE statement.

SELECT * FROM
(WITH babies_by_decade AS (SELECT (CASE WHEN Year BETWEEN 1980 AND 1989 THEN 'Eighties'
					WHEN Year BETWEEN 1990 AND 1999 THEN 'Nineties'
                                        WHEN Year BETWEEN 2000 and 2009 THEN 'Two_Thousands'
                                        ELSE 'None' END) AS Decade,
        Gender, Name, SUM(births) AS num_babies
		FROM names
		GROUP BY Decade, Gender, Name)
SELECT Decade, Gender, Name, num_babies,
	ROW_NUMBER() OVER (PARTITION BY decade, Gender ORDER BY num_babies DESC) AS Popularity
FROM babies_by_decade) AS top_three
WHERE Popularity < 4;

-- Objective 3 - COMPARE POPULARITY ACROSS REGIONS
SELECT * FROM regions;

-- Query to see what all the regions look like initally
SELECT DISTINCT (Region)
FROM regions; 

-- Query to fix the discrepancy between New England and New_England
WITH clean_regions AS
	 (SELECT State, 
	CASE WHEN Region = 'New England' THEN 'New_England' 
	ELSE Region END AS clean_region
    FROM regions)
    
SELECT DISTINCT clean_region FROM clean_regions;

-- Join names table with newly created cleaned_regions table, 
-- this result gives a NULL meaning there are states in the names table that aren't in the clean_regions table

WITH clean_regions AS
	 (SELECT State, 
	CASE WHEN Region = 'New England' THEN 'New_England' 
	ELSE Region END AS clean_region
    FROM regions)
    
SELECT DISTINCT clean_region 
FROM names n LEFT JOIN clean_regions cr
ON n.State = cr.State;

-- Check to see what state is coming back as null --> (it's Michigan) 
-- Michigan is supposed to be in the midwest region so add in a UNION and make that change. 

WITH clean_regions AS
	 (SELECT State, 
	CASE WHEN Region = 'New England' THEN 'New_England' 
	ELSE Region END AS clean_region
    FROM regions
    UNION
    SELECT 'MI' AS State, 'Midwest' AS Region)
    
SELECT DISTINCT n.State, cr.clean_region 
FROM names n LEFT JOIN clean_regions cr
ON n.State = cr.State;

-- Now answer the original question, return the number of babies born in each of the 6 regions

WITH clean_regions AS
	 (SELECT State, 
	CASE WHEN Region = 'New England' THEN 'New_England' 
	ELSE Region END AS clean_region
    FROM regions
    UNION
    SELECT 'MI' AS State, 'Midwest' AS Region)
    
SELECT clean_region, SUM(Births) AS num_babies 
FROM names n LEFT JOIN clean_regions cr
ON n.State = cr.State
GROUP BY clean_region;

-- Return the 3 most popular girl names and 3 most popular boy names within each region

SELECT * FROM

(WITH babies_by_region AS (	
        WITH clean_regions AS
			 (SELECT State, 
			CASE WHEN Region = 'New England' THEN 'New_England' 
			ELSE Region END AS clean_region
			FROM regions
			UNION
			SELECT 'MI' AS State, 'Midwest' AS Region)
			
		SELECT cr.clean_region, n.Gender, n.Name, SUM(n.Births) AS num_babies
		FROM names n LEFT JOIN clean_regions cr
		ON n.State = cr.State
		GROUP BY cr.clean_region, n.Gender, n.Name)
        
SELECT clean_region, Gender, Name,
		ROW_NUMBER() OVER (PARTITION BY clean_region, Gender ORDER BY num_babies DESC) AS popularity
FROM babies_by_region) AS region_popularity

WHERE popularity < 4;

-- We see that for all of the regions (except the South) the most popular baby names were Jessica & Michael. 
-- In the South, the most popular names were Christopher and Ashley during those decades. 

-- Objective #4 - DIG INTO SOME UNIQUE NAMES

-- 1. Find the 10 most popular androgynous names 

SELECT Name, COUNT(DISTINCT Gender) AS num_genders, SUM(Births) AS num_babies
FROM names
GROUP BY Name
HAVING num_genders = 2
ORDER BY num_babies DESC
LIMIT 10;

-- 2. Find the length of the shortest and longest names. 
-- Identify the most popular short names & most popular long names.

SELECT Name, LENGTH(Name) as name_length
FROM names
ORDER BY name_length; 
-- result: length of short name = 2 characters

SELECT Name, LENGTH(Name) as name_length
FROM names
ORDER BY name_length DESC; 
-- length of long name = 15 characters

WITH short_long_names AS (SELECT *
FROM names
WHERE LENGTH(Name) IN (2,15))

SELECT Name, SUM(Births) AS num_babies
FROM short_long_names
GROUP BY Name
ORDER BY num_babies DESC;


-- 3. Find the state with the highest percent of babies named Nicole
-- This query will return the numerator --> (number of Nicole's) 
SELECT State, SUM(Births) AS num_nicole
FROM Names
WHERE Name = 'Nicole'
GROUP BY State;

-- This query returns all babies and will be the denominator for percentage.
SELECT State, SUM(Births) AS num_babies
FROM Names
GROUP BY State;

-- So now just join the two tables together
SELECT State, ROUND(num_nicole / num_babies * 100, 2) AS pct_nicole
FROM

(WITH count_nicole AS  (SELECT State, SUM(Births) AS num_nicole
		FROM Names
		WHERE Name = 'Nicole'
		GROUP BY State),

count_all AS (SELECT State, SUM(Births) AS num_babies
FROM Names
GROUP BY State)

SELECT cc.State, cc.num_nicole, ca.num_babies
FROM count_nicole cc INNER JOIN count_all ca
    ON cc.State = ca.State) AS state_nicole_all
    
    ORDER BY pct_nicole;

-- Output shows RI had the highest percentage of babies born with the name Nicole and MS had the lowest.
