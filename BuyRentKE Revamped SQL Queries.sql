CREATE DATABASE PropertyListingsKE

SELECT TOP 10*
FROM kenya_properties_full;

--Create working table
SELECT*
INTO Clean_Kenya_Properties
FROM kenya_properties_full;

--Row count
SELECT COUNT(*) AS total_rows
FROM Clean_Kenya_Properties;

SELECT TOP 2*
FROM Clean_Kenya_Properties;

-- Null / zero audit
SELECT
    SUM(CASE WHEN Listing_ID IS NULL THEN 1 ELSE 0 END) AS null_listing_id,
    SUM(CASE WHEN Title IS NULL THEN 1 ELSE 0 END) AS null_title,
    SUM(CASE WHEN Price_Ksh IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Price_ksh = 0 THEN 1 ELSE 0 END) AS zero_price,
    SUM(CASE WHEN Area_Sqft IS NULL THEN 1 ELSE 0 END) AS null_area,
    SUM(CASE WHEN Bedrooms IS NULL THEN 1 ELSE 0 END) AS null_bedrooms,
    SUM(CASE WHEN County IS NULL THEN 1 ELSE 0 END) AS null_county,
	SUM(CASE WHEN Property_Type IS NULL THEN 1 ELSE 0 END) AS null_property_type,
	SUM(CASE WHEN Specific_Type IS NULL THEN 1 ELSE 0 END) AS null_specific_type,
	SUM(CASE WHEN Area_Sqft IS NULL THEN 1 ELSE 0 END) AS null_area,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN Area_Name IS NULL THEN 1 ELSE 0 END) AS null_area_name
FROM Clean_Kenya_Properties;

-- Checking description of null and 0 prices
SELECT Title
FROM Clean_Kenya_Properties
WHERE Price_Ksh IS NULL OR Price_Ksh = 0;

-- Checking description of null Areas
SELECT Title
FROM Clean_Kenya_Properties
WHERE Area_Sqft IS NULL;

-- Duplicate listing_ids
SELECT Listing_ID, Title, Property_Type, COUNT(*) AS cnt
FROM Clean_Kenya_Properties
GROUP BY Listing_ID, Title, Property_Type
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

--County name variants
SELECT County, COUNT(*) AS cnt
FROM Clean_Kenya_Properties
GROUP BY County
ORDER BY cnt DESC;

--Removing Exact Duplicates
WITH Cte_Dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY Listing_ID
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM Clean_Kenya_Properties
)
DELETE FROM Cte_Dedup WHERE rn > 1;

-- Confirm: should now be 6,997 rows
SELECT COUNT(*) AS rows_after_dedup
FROM Clean_Kenya_Properties;

--Standardising county names
ALTER TABLE Clean_Kenya_Properties
    ADD County_Clean NVARCHAR(100);

UPDATE Clean_Kenya_Properties
SET County_Clean = CASE
    WHEN County = 'Nairobi' THEN 'Nairobi'
    WHEN County = 'Mombasa' THEN 'Mombasa'
    WHEN County = 'Kisumu' THEN 'Kisumu'
    WHEN County = 'Nakuru County' THEN 'Nakuru'
    WHEN County = 'Kiambu County' THEN 'Kiambu'
    WHEN County = 'Kajiado County' THEN 'Kajiado'
    WHEN County = 'Machakos County' THEN 'Machakos'
    WHEN County = 'Kilifi County' THEN 'Kilifi'
    WHEN County = 'Kwale County' THEN 'Kwale'
    WHEN County = 'Laikipia' THEN 'Laikipia'
    WHEN County = 'Muranga County' THEN 'Muranga'
    WHEN County = 'Nyandarua County' THEN 'Nyandarua'
    WHEN County = 'Nyeri' THEN 'Nyeri'
    WHEN County = 'Narok' THEN 'Narok'
    WHEN County = 'Kirinyaga' THEN 'Kirinyaga'
    WHEN County = 'Eldoret' THEN 'Uasin Gishu'  -- Eldoret is a city in Uasin Gishu
    WHEN County = 'Kitui' THEN 'Kitui'
    WHEN County = 'Taita-Taveta' THEN 'Taita-Taveta'
    WHEN County = 'Meru' THEN 'Meru'
    ELSE County
END;

-- Add region grouping (useful for Power BI map hierarchy)
ALTER TABLE Clean_Kenya_Properties
    ADD county_region NVARCHAR(50);

ALTER TABLE Clean_Kenya_Properties
DROP COLUMN county_region;

ALTER TABLE Clean_Kenya_Properties
    ADD County_Region NVARCHAR(50);


UPDATE Clean_Kenya_Properties
SET County_Region = CASE
    WHEN County_Clean IN ('Nairobi', 'Kiambu', 'Kajiado', 'Machakos',
                          'Muranga', 'Nyandarua', 'Kirinyaga', 'Nyeri',
                          'Laikipia', 'Narok') THEN 'Central & Nairobi Metro'
    WHEN County_Clean IN ('Mombasa', 'Kilifi', 'Kwale', 'Taita-Taveta') THEN 'Coast'
    WHEN County_Clean IN ('Kisumu', 'Nakuru', 'Uasin Gishu') THEN 'Rift Valley & Western'
    WHEN County_Clean IN ('Kitui', 'Meru') THEN 'Eastern'
    ELSE 'Other'
END;

-- Clean Property Type & Specific Type
 -- Stripping " for sale" suffix for cleaner labels in visuals.
ALTER TABLE Clean_Kenya_Properties
    ADD Property_Type_Clean  NVARCHAR(50),
        Specific_Type_Clean  NVARCHAR(100);

UPDATE Clean_Kenya_Properties
SET Property_Type_Clean = CASE
    WHEN Property_Type = 'Apartments for sale' THEN 'Apartment'
    WHEN Property_Type = 'Houses for sale' THEN 'House'
    WHEN Property_Type = 'Land for sale' THEN 'Land'
    WHEN Property_Type = 'Commercial Property for sale' THEN 'Commercial'
    ELSE 'Other'
END;

UPDATE Clean_Kenya_Properties
SET Specific_Type_Clean = CASE
    WHEN Specific_Type = 'Other Apartments for sale' THEN 'Apartment'
    WHEN Specific_Type = 'Other Houses for sale' THEN 'House'
    WHEN Specific_Type = 'Other Land for sale' THEN 'Land'
    WHEN Specific_Type = 'Townhouses for sale' THEN 'Townhouse'
    WHEN Specific_Type = 'Villas for sale' THEN 'Villa'
    WHEN Specific_Type = 'Residential Land for sale' THEN 'Residential Land'
    WHEN Specific_Type = 'Commercial Land for sale' THEN 'Commercial Land'
    WHEN Specific_Type = 'Other Commercial Property for sale' THEN 'Commercial Property'
    WHEN Specific_Type = 'Warehouses for sale' THEN 'Warehouse'
    WHEN Specific_Type = 'Offices for sale' THEN 'Office'
    WHEN Specific_Type = 'Shops for sale' THEN 'Shop'
    ELSE Specific_Type
END;

 -- HANDLING PRICE ISSUES
  -- Issues found:
    -- 37 NULL prices - flag as 'Price Not Disclosed'
     -- 13 zero prices - treat same as NULL (not free)
     -- 16 prices > 1 Billion - legitimate luxury/commercial, retain but flag as 'Ultra Premium'
   -- We do NOT delete any rows — we flag them and let Power BI slicers let the user include/exclude them.
-- Normalise zero prices to NULL (zero = not disclosed)
UPDATE Clean_Kenya_Properties
SET Price_Ksh = NULL
WHERE Price_Ksh = 0;

-- Add price flag column
ALTER TABLE Clean_Kenya_Properties
    ADD Price_Flag NVARCHAR(50);

UPDATE Clean_Kenya_Properties
SET Price_Flag = CASE
    WHEN Price_Ksh IS NULL THEN 'Price Not Disclosed'
    WHEN Price_Ksh > 1000000000 THEN 'Ultra Premium (>1B)'
    WHEN Price_Ksh < 500000 THEN 'Low'
    ELSE 'Standard'
END;

-- Verify distribution
SELECT Price_Flag, COUNT(*) AS cnt
FROM Clean_Kenya_Properties
GROUP BY Price_Flag
ORDER BY cnt DESC;

--HANDLING AREA SQUARE FT ISSUES
-- 64.5% of rows have no area — this is normal for land/plots where area is in acres not sqft.
-- Issues:
-- 17 zero values -- set to NULL
-- 6 values > 100,000 sqft -- likely data entry errors (land listed in sqft but value was actually acres)
-- Flag rather than delete.
-- Zero area = NULL
UPDATE Clean_Kenya_Properties
SET Area_Sqft = NULL
WHERE Area_Sqft = 0;

-- Add area flag
ALTER TABLE Clean_Kenya_Properties
    ADD Area_Flag NVARCHAR(50);

UPDATE Clean_Kenya_Properties
SET Area_Flag = CASE
    WHEN Area_Sqft IS NULL THEN 'Not Available'
    WHEN Area_Sqft > 100000 THEN 'Review - Unusually Large'
    ELSE 'Available'
END;

--Deriving Price band for price distribution charts and affordability KPIs
ALTER TABLE Clean_Kenya_Properties
    ADD Price_Band NVARCHAR(50),
        Price_Band_Sort INT;

UPDATE Clean_Kenya_Properties
SET
    Price_Band = CASE
        WHEN Price_Ksh IS NULL THEN 'Not Disclosed'
        WHEN Price_Ksh < 5000000 THEN 'Entry-Level (<5M)'
        WHEN Price_Ksh < 15000000 THEN 'Affordable (5M–15M)'
        WHEN Price_Ksh < 40000000 THEN 'Mid-Market (15M–40M)'
        WHEN Price_Ksh < 100000000 THEN 'Upper-Mid (40M–100M)'
        ELSE 'Luxury (>100M)'
    END,
    Price_Band_Sort = CASE
        WHEN Price_Ksh IS NULL THEN 0
        WHEN Price_Ksh < 5000000 THEN 1
        WHEN Price_Ksh < 15000000 THEN 2
        WHEN Price_Ksh < 40000000 THEN 3
        WHEN Price_Ksh < 100000000 THEN 4
        ELSE 5
    END;

-- Verify
SELECT Price_Band, Price_Band_Sort, COUNT(*) AS cnt
FROM Clean_Kenya_Properties
GROUP BY Price_Band, Price_Band_Sort
ORDER BY Price_Band_Sort;

--Deriving Bedroom Category
-- Consolidating bedroom counts into display-friendly buckets.
-- Bedrooms = 0 means Studio or Land (no bedrooms).
ALTER TABLE Clean_Kenya_Properties
    ADD Bedroom_Category NVARCHAR(30),
        Bedroom_Sort INT;

UPDATE Clean_Kenya_Properties
SET
    Bedroom_Category = CASE
        WHEN Bedrooms = 0  THEN 'Studio / N/A'
        WHEN Bedrooms = 1  THEN '1 Bedroom'
        WHEN Bedrooms = 2  THEN '2 Bedrooms'
        WHEN Bedrooms = 3  THEN '3 Bedrooms'
        WHEN Bedrooms = 4  THEN '4 Bedrooms'
        WHEN Bedrooms = 5  THEN '5 Bedrooms'
        WHEN Bedrooms >= 6 THEN '6+ Bedrooms'
        ELSE 'Unknown'
    END,
    Bedroom_Sort = CASE
        WHEN Bedrooms = 0  THEN 0
        WHEN Bedrooms = 1  THEN 1
        WHEN Bedrooms = 2  THEN 2
        WHEN Bedrooms = 3  THEN 3
        WHEN Bedrooms = 4  THEN 4
        WHEN Bedrooms = 5  THEN 5
        WHEN Bedrooms >= 6 THEN 6
        ELSE 99
    END;

-- Top 10 locations by listing volume
SELECT TOP 10 Area_Name, County_Clean, COUNT(*) AS Listings,
       ROUND(AVG(Price_Ksh) / 1000000.0, 1) AS Avg_Price
FROM Clean_Kenya_Properties
WHERE Price_Flag = 'Standard'
GROUP BY Area_Name, County_Clean
ORDER BY Listings DESC;