-- remove the view if it exists in order to start fresh
DROP VIEW IF EXISTS v_footfall_weather_impact;

-- create master view for power bi
-- combine weather and footfall into one table
CREATE VIEW v_footfall_weather_impact AS
SELECT 
    f.Date,
    f.DayOFWeek,
    f.Station,
    -- use CAST to force these into integers
    CAST(f.EntryTapCount AS INTEGER) AS EntryTapCount,
    CAST(f.ExitTapCount AS INTEGER) AS ExitTapCount,
    -- force the calculation into an integer
    CAST((f.EntryTapCount + f.ExitTapCount) AS INTEGER) AS Total_Taps,
    -- force Temp into a Float (Decimal)
    CAST(w.Temp AS FLOAT) AS Temp,
    w.Precip,
    -- simplify conditions for better charting
    CASE 
        WHEN w.conditions LIKE '%Storm%' THEN 'Stormy'
        WHEN w.conditions LIKE '%Rain%' THEN 'Rainy'
        WHEN w.conditions LIKE '%Snow%' THEN 'Snowy'
        WHEN w.conditions LIKE '%Overcast%' THEN 'Overcast'
        WHEN w.conditions LIKE '%Clear%' THEN 'Clear'
        WHEN w.conditions LIKE '%Wind%' THEN 'Windy'
        ELSE 'Cloudy/Other'
    END AS Weather_Category,
    w.conditions AS Raw_Conditions -- keep the original just in case
FROM footfall f
LEFT JOIN weather w ON f.Date = w.Date;



-- average Footfall by Temperature Degree
-- identify the 'Tipping Point'
SELECT 
    CAST(Temp AS INT) AS Temp_Bucket,
    AVG(Total_Taps) AS Avg_Station_Footfall
FROM v_footfall_weather_impact
WHERE Station IN (
    SELECT Station 
    FROM v_footfall_weather_impact 
    GROUP BY Station 
    ORDER BY AVG(Total_Taps) DESC 
    LIMIT 50)
GROUP BY Temp_Bucket
ORDER BY Temp_Bucket ASC;



-- footfall vs. Weather Category
SELECT 
    Weather_Category,
    AVG(Total_Taps) AS Avg_Daily_Taps
FROM v_footfall_weather_impact
WHERE Station IN (
    SELECT Station 
    FROM v_footfall_weather_impact 
    GROUP BY Station 
    ORDER BY AVG(Total_Taps) DESC 
    LIMIT 50)
GROUP BY Weather_Category
ORDER BY Avg_Daily_Taps DESC;



-- which stations see the biggest drop on 'Rainy' days?
SELECT 
    Station,
    Weather_Category,
    AVG(Total_Taps) as Avg_Taps
FROM v_footfall_weather_impact
WHERE Weather_Category IN ('Stormy','Rainy', 'Overcast', 'Clear')
GROUP BY Station, Weather_Category
LIMIT 50;


-- how much rain causes footfall to decrease
SELECT 
    ROUND(Precip, 0) AS Rain_mm,
    AVG(Total_Taps) AS Avg_Footfall
FROM v_footfall_weather_impact
WHERE Station IN (
    SELECT Station 
    FROM v_footfall_weather_impact 
    GROUP BY Station 
    ORDER BY AVG(Total_Taps) DESC 
    LIMIT 50
)
GROUP BY Rain_mm
ORDER BY Rain_mm ASC;


-- how does footfall respond to weather over different months
SELECT 
    strftime('%Y-%m', Date) AS YearMonth,
    AVG(Total_Taps) AS Avg_Monthly_Footfall,
    AVG(Temp) AS Avg_Month_Temp,
    AVG(Precip) AS Avg_Month_Rain
FROM v_footfall_weather_impact
WHERE Station IN (
    SELECT Station 
    FROM v_footfall_weather_impact 
    GROUP BY Station 
    ORDER BY AVG(Total_Taps) DESC 
    LIMIT 50)
GROUP BY YearMonth
ORDER BY YearMonth ASC;

-- check results
--SELECT * FROM v_footfall_weather_impact LIMIT 10;