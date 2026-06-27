/*
  Analytical query: distribution of friend counts by gender and city
  – Counts distinct friends for each person (undirected relationship).
  – Aggregates per gender + location_city_id: number of persons, average, median, max and min friend counts.
*/
WITH friends AS (
    SELECT
        person1_id AS person_id,
        person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT
        person2_id AS person_id,
        person1_id AS friend_id
    FROM person_knows_person
),
friend_counts AS (
    SELECT
        person_id,
        COUNT(DISTINCT friend_id) AS friend_cnt
    FROM friends
    GROUP BY person_id
),
person_info AS (
    SELECT
        id,
        gender,
        location_city_id
    FROM person
)
SELECT
    pi.gender,
    pi.location_city_id,
    COUNT(*) AS person_cnt,
    AVG(COALESCE(fc.friend_cnt, 0)) AS avg_friend_cnt,
    approx_percentile(COALESCE(fc.friend_cnt, 0), 0.5) AS median_friend_cnt,
    MAX(COALESCE(fc.friend_cnt, 0)) AS max_friend_cnt,
    MIN(COALESCE(fc.friend_cnt, 0)) AS min_friend_cnt
FROM person_info pi
LEFT JOIN friend_counts fc
    ON fc.person_id = pi.id
GROUP BY pi.gender, pi.location_city_id
ORDER BY pi.gender, pi.location_city_id
