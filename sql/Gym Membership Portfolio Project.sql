/*========================================================
    Project: Gym Membership Analytics
    Author: Larson St-Cyr
    Tools Used: Excel, SQL Server, Tableau Public
    Description:
    Data cleaning, validation, and exploratory analysis
    performed on a gym membership dataset sourced
    from Kaggle.

========================================================*/


/*========================================================
    DATABASE PREVIEW
========================================================*/

SELECT *
FROM dbo.Gym_Membership;



/*========================================================
    CREATE STAGING TABLE
========================================================*/

SELECT *
INTO dbo.Gym_Membership_Staging
FROM dbo.Gym_Membership;

SELECT *
FROM dbo.Gym_Membership_Staging

/*========================================================
    DATA QUALITY CHECKS
========================================================*/

-- Check for NULL values across all major columns

SELECT 
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS gender_nulls,
    SUM(CASE WHEN birthday IS NULL THEN 1 ELSE 0 END) AS birthday_nulls,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS age_nulls,
    SUM(CASE WHEN membership_type IS NULL THEN 1 ELSE 0 END) AS membership_nulls,
    SUM(CASE WHEN weekly_visits IS NULL THEN 1 ELSE 0 END) AS weekly_visits_nulls,
    SUM(CASE WHEN days_per_week IS NULL THEN 1 ELSE 0 END) AS days_per_week_nulls,
    SUM(CASE WHEN attend_group_classes IS NULL THEN 1 ELSE 0 END) AS attend_classes_nulls,
    SUM(CASE WHEN favorite_group_classes IS NULL THEN 1 ELSE 0 END) AS favorite_classes_nulls,
    SUM(CASE WHEN avg_check_in_time IS NULL THEN 1 ELSE 0 END) AS checkin_nulls,
    SUM(CASE WHEN avg_check_out_time IS NULL THEN 1 ELSE 0 END) AS checkout_nulls,
    SUM(CASE WHEN avg_time_in_gym IS NULL THEN 1 ELSE 0 END) AS gym_time_nulls,
    SUM(CASE WHEN purchases_drink IS NULL THEN 1 ELSE 0 END) AS drink_purchase_nulls,
    SUM(CASE WHEN favorite_drink IS NULL THEN 1 ELSE 0 END) AS favorite_drink_nulls,
    SUM(CASE WHEN personal_training IS NULL THEN 1 ELSE 0 END) AS personal_training_nulls,
    SUM(CASE WHEN personal_trainer_name IS NULL THEN 1 ELSE 0 END) AS trainer_name_nulls,
    SUM(CASE WHEN uses_sauna IS NULL THEN 1 ELSE 0 END) AS sauna_nulls
FROM dbo.Gym_Membership_Staging;



/*========================================================
    DATA STANDARDIZATION
========================================================*/

-- Standardize favorite_drink formatting
-- Example:
-- berry_boost --> Berry Boost

UPDATE dbo.Gym_Membership_Staging
SET favorite_drink =
(
    SELECT STRING_AGG(
        UPPER(LEFT(word, 1)) +
        LOWER(SUBSTRING(word, 2, LEN(word))),
        ', '
    )
    FROM
    (
        SELECT REPLACE(LTRIM(RTRIM(value)), '_', ' ') AS word
        FROM STRING_SPLIT(favorite_drink, ',')
    ) AS words
)
WHERE favorite_drink IS NOT NULL;



/*========================================================
    VALIDATION CHECKS
========================================================*/

-- Identify records where checkout time occurs before check-in time

SELECT *
FROM dbo.Gym_Membership_Staging
WHERE avg_check_out_time < avg_check_in_time;



-- Identify invalid weekly visit values

SELECT *
FROM dbo.Gym_Membership_Staging
WHERE weekly_visits > 7;



-- Identify members assigned a trainer without personal training enabled

SELECT *
FROM dbo.Gym_Membership_Staging
WHERE personal_training = 0
AND personal_trainer_name IS NOT NULL;



/*========================================================
    EXPLORATORY DATA ANALYSIS (EDA)
========================================================*/


------ Membership Distribution ------

SELECT 
    membership_type,
    COUNT(*) AS total_members
FROM dbo.Gym_Membership_Staging
GROUP BY membership_type
ORDER BY total_members DESC;



------ Average Gym Time by Membership Type ------

SELECT 
    membership_type,
    AVG(avg_time_in_gym) AS avg_minutes_in_gym
FROM dbo.Gym_Membership_Staging
GROUP BY membership_type;




------ Peak Check-In Hours ------


SELECT 
    DATEPART(HOUR, avg_check_in_time) AS checkin_hour,
    COUNT(*) AS total_visits
FROM dbo.Gym_Membership_Staging
GROUP BY DATEPART(HOUR, avg_check_in_time)
ORDER BY total_visits DESC;



------    Sauna Usage by Gender ------


SELECT 
    gender,
    SUM(CASE WHEN uses_sauna = 1 THEN 1 ELSE 0 END) AS sauna_users
FROM dbo.Gym_Membership_Staging
GROUP BY gender;



------ Personal Training Adoption Rate ------


SELECT 
    membership_type,
    AVG(
        CASE 
            WHEN personal_training = 1 THEN 1.0
            ELSE 0
        END
    ) * 100 AS personal_training_percentage
FROM dbo.Gym_Membership_Staging
GROUP BY membership_type;



------ Average Weekly Visits by Age Group ------


SELECT
    CASE
        WHEN age BETWEEN 10 AND 19 THEN '10-19'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS age_group,

    AVG(weekly_visits) AS avg_weekly_visits

FROM dbo.Gym_Membership_Staging

GROUP BY
    CASE
        WHEN age BETWEEN 10 AND 19 THEN '10-19'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END

ORDER BY avg_weekly_visits DESC;



------ Member Engagement Score ------


SELECT
    id,
    membership_type,
    weekly_visits,
    avg_time_in_gym,

    (weekly_visits * avg_time_in_gym)
        AS engagement_score

FROM dbo.Gym_Membership_Staging

ORDER BY engagement_score DESC;



------ Average Member Age by Membership Type ------


SELECT
    membership_type,
    AVG(age) AS avg_member_age
FROM dbo.Gym_Membership_Staging
GROUP BY membership_type;



------ Drink Purchase Behavior ------


SELECT
    purchases_drink,
    AVG(avg_time_in_gym) AS avg_minutes_in_gym
FROM dbo.Gym_Membership_Staging
GROUP BY purchases_drink;



------ Most Requested Personal Trainers ------


SELECT
    personal_trainer_name,
    COUNT(*) AS total_clients
FROM dbo.Gym_Membership_Staging
WHERE personal_trainer_name IS NOT NULL
GROUP BY personal_trainer_name
ORDER BY total_clients DESC;



------ Most Popular Group Fitness Classes ------


SELECT
    TRIM(value) AS class_name,
    COUNT(*) AS popularity
FROM dbo.Gym_Membership_Staging
CROSS APPLY STRING_SPLIT(favorite_group_classes, ',')
GROUP BY TRIM(value)
ORDER BY popularity DESC;



------ Membership Percentage Breakdown ------


SELECT
    membership_type,
    COUNT(*) AS total_members,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) 
         FROM dbo.Gym_Membership_Staging),
        2
    ) AS percentage_of_members
FROM dbo.Gym_Membership_Staging
GROUP BY membership_type;


-----------------------------------------------------
------------- Final Clean Table ---------------------
-----------------------------------------------------

SELECT *
INTO dbo.Gym_Membership_Cleaned
FROM dbo.Gym_Membership_Staging;


SELECT *
FROM dbo.Gym_Membership_Cleaned;

