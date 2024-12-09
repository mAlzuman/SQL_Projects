# World Life Expectancy Project

# Data Cleaning: Retrieve all records from the World_Life_Expectancy table.
SELECT 
    *
FROM
    World_Life_Expectancy;

# Identify duplicate entries based on Country and Year.
SELECT 
    Country,
    Year,
    CONCAT(Country, Year) AS country_year,  # Create a concatenated identifier for each Country-Year pair.
    COUNT(CONCAT(Country, Year)) AS Count    # Count occurrences of each Country-Year pair.
FROM
    World_Life_Expectancy
GROUP BY Country, Year, CONCAT(Country, Year)  # Group by Country and Year.
HAVING COUNT(CONCAT(Country, Year)) > 1;       # Filter to only show duplicates.

# Create a Common Table Expression (CTE) to rank countries based on Row_ID.
WITH RankedCountries AS (
    SELECT Row_ID,
        CONCAT(Country, Year) AS country_year,
        ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY Row_ID) AS Row_Num  # Assign a row number to each duplicate.
    FROM World_Life_Expectancy
)

# Select all rows where Row_Num is greater than 1 (indicating duplicates).
SELECT 
    *
FROM
    RankedCountries
WHERE
    Row_Num > 1;

# Disable safe updates to allow deletions.
SET SQL_SAFE_UPDATES = 0;

# Delete duplicate entries from the World_Life_Expectancy table.
DELETE FROM World_Life_Expectancy 
WHERE Row_ID IN (
    WITH RankedCountries AS (
        SELECT Row_ID,
            CONCAT(Country, Year) AS country_year,
            ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY Row_ID) AS Row_Num 
        FROM World_Life_Expectancy
    )
    SELECT 
        Row_ID
    FROM 
        RankedCountries 
    WHERE Row_Num > 1
);

# Select records where the Status is empty.
SELECT 
    *
FROM
    World_Life_Expectancy
WHERE
    Status = '';

# Check for distinct statuses in the dataset (should be 'Developing' or 'Developed').
SELECT DISTINCT
    Status
FROM
    World_Life_Expectancy
WHERE
    Status <> '';

# To populate the status of the country:
# First, check if the country's status has changed over the years.
SELECT 
    Country,
    COUNT(DISTINCT Status) AS DIS_count  # Count distinct statuses for each country.
FROM
    World_Life_Expectancy 
WHERE
    Status <> '' 
GROUP BY Country
HAVING COUNT(DISTINCT Status) > 1;  # Filter to countries with multiple statuses.

# Update the status for countries that have a non-empty status in another year.
UPDATE World_Life_Expectancy t1
JOIN World_Life_Expectancy t2 ON t1.Country = t2.Country 
SET 
    t1.Status = 'Developing'  # Set status to 'Developing' for t1.
WHERE
    t1.Status = '' AND t2.Status <> ''  # Only update if t1 has no status and t2 has a status.
    AND t2.Status = 'Developing';

# Update the status for countries to 'Developed' based on other years' statuses.
UPDATE World_Life_Expectancy t1
JOIN World_Life_Expectancy t2 ON t1.Country = t2.Country 
SET 
    t1.Status = 'Developed'  # Set status to 'Developed' for t1.
WHERE
    t1.Status = '' AND t2.Status <> ''  # Only update if t1 has no status and t2 has a status.
    AND t2.Status = 'Developed';

# Check again to ensure all statuses have been populated.
SELECT 
    *
FROM
    World_Life_Expectancy
WHERE
    Status IS NULL;

# Select entries with empty life expectancy values.
SELECT Country,
Year,
`Life expectancy`
FROM  World_Life_Expectancy
WHERE   `Life expectancy` = ''; 


# Retrieve life expectancy data across three years for comparison.
SELECT t1.Country,
t1.Year,
t1.`Life expectancy`,
t2.Country,
t2.Year,
t2.`Life expectancy`,
t3.Country,
t3.Year,
t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1)  # Calculate the average life expectancy for t1.
FROM  World_Life_Expectancy t1
JOIN World_Life_Expectancy t2 
    ON t1.Country = t2.Country 
    AND t1.YEAR = t2.Year - 1  # Join with the previous year's data.
JOIN World_Life_Expectancy t3
    ON t1.Country = t3.Country 
    AND t1.YEAR = t3.Year + 1  # Join with the next year's data.
WHERE t1.`Life expectancy` = '';  # Filter for records with missing life expectancy.


# Update the missing life expectancy values based on averages from surrounding years.
UPDATE World_Life_Expectancy t1
JOIN World_Life_Expectancy t2 
    ON t1.Country = t2.Country 
    AND t1.YEAR = t2.Year - 1 
JOIN World_Life_Expectancy t3
    ON t1.Country = t3.Country 
    AND t1.YEAR = t3.Year + 1 
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1)  # Set the average life expectancy.
WHERE t1.`Life expectancy` = '';  # Only update where life expectancy is missing.





-- Exploratory Data Analysis: Analyzing life expectancy patterns by country
SELECT Country,
    MIN(`life expectancy`) AS Min_Life_Expectancy,  -- Minimum life expectancy in the country
    MAX(`life expectancy`) AS Max_Life_Expectancy,  -- Maximum life expectancy in the country
    ROUND(MAX(`life expectancy`) - MIN(`life expectancy`), 1) AS Life_Increase_15_Years  -- Increase in life expectancy over the years
FROM World_Life_Expectancy
GROUP BY Country  -- Group results by country
HAVING MAX(`life expectancy`) <> 0  -- Exclude countries with max life expectancy of 0
AND MIN(`life expectancy`) <> 0  -- Exclude countries with min life expectancy of 0
ORDER BY Life_Increase_15_Years DESC;  -- Order by the increase in life expectancy, descending



-- Average life expectancy by year
SELECT Year,
    ROUND(AVG(`Life expectancy`), 1) AS Avg_Life_Expectancy  -- Calculate average life expectancy for each year
FROM World_Life_Expectancy
WHERE `Life expectancy` <> 0  -- Exclude records with life expectancy of 0
GROUP BY Year  -- Group results by year
ORDER BY AVG(`Life expectancy`) DESC;  -- Order by average life expectancy, descending




-- Average life expectancy and GDP by country
SELECT Country,
    ROUND(AVG(`Life expectancy`), 1) AS Life_Exp,  -- Average life expectancy in the country
    ROUND(AVG(GDP), 1) AS GDP  -- Average GDP in the country
FROM World_Life_Expectancy
GROUP BY Country  -- Group results by country
HAVING Life_Exp > 0  -- Exclude countries with average life expectancy of 0
AND GDP > 1  -- Exclude countries with GDP less than or equal to 1
ORDER BY GDP DESC;  -- Order by GDP, descending



-- Counts and averages based on GDP thresholds
SELECT 
    SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_COUNT,  -- Count countries with high GDP
    ROUND(AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END), 1) AS High_GDP_Life_Exp,  -- Average life expectancy for high GDP countries
    SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END) AS Low_GDP_COUNT,  -- Count countries with low GDP
    ROUND(AVG(CASE WHEN GDP < 1500 THEN `Life expectancy` ELSE NULL END), 1) AS Low_GDP_Life_Exp  -- Average life expectancy for low GDP countries
FROM World_Life_Expectancy;



-- Life expectancy and average by status
SELECT Status,
    COUNT(DISTINCT Country) AS COUNT,  -- Count distinct countries by status
    ROUND(AVG(`Life expectancy`), 1) AS AVG_life_exp  -- Average life expectancy by status
FROM World_Life_Expectancy
GROUP BY Status;  -- Group results by status



-- Average life expectancy and BMI by country
SELECT Country,
    ROUND(AVG(`Life expectancy`), 1) AS Life_Exp,  -- Average life expectancy in the country
    ROUND(AVG(BMI), 1) AS BMI  -- Average BMI in the country
FROM World_Life_Expectancy
GROUP BY Country  -- Group results by country
HAVING Life_Exp > 0  -- Exclude countries with average life expectancy of 0
AND BMI > 0  -- Exclude countries with average BMI of 0
ORDER BY BMI DESC;  -- Order by BMI, descending



-- Rolling total of adult mortality by country and year
SELECT 
    Country,
    Year,
    `Life expectancy`,  -- Life expectancy for the year
    `Adult Mortality`,  -- Adult mortality rate for the year
    SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total  -- Calculate rolling total of adult mortality for each country
FROM World_Life_Expectancy;