# Data Clean for us_household_income table 

-- Retrieve all records from the us_household_income table
SELECT * FROM us_household_income;

-- Count total records in the us_household_income table
SELECT COUNT(id) FROM us_household_income;

-- Identify duplicate records based on the id field
SELECT *
FROM (
    SELECT 
        row_id,
        id,
        row_number() OVER(PARTITION BY id ORDER BY id) AS row_num
    FROM us_household_income
) AS check_duplicated
WHERE row_num > 1;

-- Disable safe updates to allow deletion of records
SET SQL_SAFE_UPDATES = 0; 

-- Delete duplicate records from the us_household_income table
DELETE FROM us_household_income
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT 
            row_id,
            id,
            row_number() OVER(PARTITION BY id ORDER BY id) AS row_num
        FROM us_household_income
    ) AS check_duplicated
    WHERE row_num > 1
);

-- Retrieve distinct state names from the us_household_income table
SELECT DISTINCT State_Name FROM us_household_income;

-- Correct the misspelling of 'Georgia' in State_Name
UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

-- Standardize State_Name to capitalize the first letter and lowercase the rest
UPDATE us_household_income
SET State_Name = CONCAT(UPPER(LEFT(State_Name, 1)), LOWER(SUBSTRING(State_Name, 2)));

-- Retrieve distinct state abbreviations from the us_household_income table
SELECT DISTINCT State_ab FROM us_household_income;

-- Find records with an empty Place field
SELECT * FROM us_household_income WHERE Place = '';

-- Find records for a specific county and city
SELECT *
FROM us_household_income
WHERE County = 'Autauga County' AND City = 'Vinemont';

-- Update Place field for specific county and city
UPDATE us_household_income 
SET Place = 'Autaugaville'
WHERE County = 'Autauga County' AND City = 'Vinemont';

-- Count the number of records for each Type
SELECT Type, COUNT(Type)
FROM us_household_income
GROUP BY Type;

-- Correct the type name from 'Boroughs' to 'Borough'
UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';

-- Find records where both ALand and AWater are zero
SELECT ALand, AWater
FROM us_household_income
WHERE AWater = '0' AND ALand = '0';

-- Sum of ALand and AWater grouped by State_Name, ordered by ALand
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 2
LIMIT 10;

-- Sum of ALand and AWater grouped by State_Name, ordered by AWater
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 3
LIMIT 10;

-- Join us_household_income with us_household_income_statistics
SELECT *
FROM us_household_income i
JOIN us_household_income_statistics s ON i.id = s.id;

-- Calculate average Mean and Median for the top 10 State_Name
SELECT 
    i.State_Name,
    ROUND(AVG(s.Mean), 1) AS Average_Mean,
    ROUND(AVG(s.Median), 1) AS Average_Median
FROM us_household_income i
JOIN us_household_income_statistics s ON i.id = s.id
WHERE s.Mean <> 0
GROUP BY i.State_Name
ORDER BY 2
LIMIT 10;

-- Calculate average Mean and Median grouped by State_Name in descending order for last 10 State_Name
SELECT 
    i.State_Name,
    ROUND(AVG(s.Mean), 1) AS Average_Mean,
    ROUND(AVG(s.Median), 1) AS Average_Median
FROM us_household_income i
JOIN us_household_income_statistics s ON i.id = s.id
WHERE s.Mean <> 0
GROUP BY i.State_Name
ORDER BY 2 DESC
LIMIT 10;

-- Calculate average Mean and Median grouped by State_Name ordered by Median descending
SELECT 
    i.State_Name,
    ROUND(AVG(s.Mean), 1) AS Average_Mean,
    ROUND(AVG(s.Median), 1) AS Average_Median
FROM us_household_income i
JOIN us_household_income_statistics s ON i.id = s.id
WHERE s.Mean <> 0
GROUP BY i.State_Name
ORDER BY 3 DESC
LIMIT 10;

-- Calculate average Mean and Median grouped by Type
SELECT 
    i.Type,
    COUNT(i.Type) AS Count_Type,
    ROUND(AVG(s.Mean), 1) AS Average_Mean,
    ROUND(AVG(s.Median), 1) AS Average_Median
FROM us_household_income i
JOIN us_household_income_statistics s ON i.id = s.id
WHERE s.Mean <> 0
GROUP BY i.Type
ORDER BY 3 DESC;

-- Calculate average Mean and Median grouped by State_Name and City
SELECT 
    i.State_Name,
    i.City,
    ROUND(AVG(s.Mean), 1) AS Average_Mean,
    ROUND(AVG(s.Median), 1) AS Average_Median
FROM us_household_income i
JOIN us_household_income_statistics s ON i.id = s.id
WHERE s.Mean <> 0
GROUP BY i.State_Name, i.City
ORDER BY 3
LIMIT 20;

# Data Clean for us_household_income_statistics table 

-- Retrieve distinct state names from the us_household_income_statistics table
SELECT DISTINCT State_Name FROM us_household_income_statistics;

-- Count total records in the us_household_income_statistics table
SELECT COUNT(id) FROM us_household_income_statistics;

-- Identify duplicate records based on the id field in the us_household_income_statistics table
SELECT id, COUNT(id)
FROM us_household_income_statistics
GROUP BY id
HAVING COUNT(id) > 1;