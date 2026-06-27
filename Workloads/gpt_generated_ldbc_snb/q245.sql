WITH city_agg AS (
    SELECT
        c.id AS city_id,
        c.name AS city_name,
        r.id AS region_id,
        r.name AS region_name,
        COUNT(*) AS person_count,
        COUNT(DISTINCT p.browser_used) AS distinct_browser_count,
        COUNT(CASE WHEN p.gender = 'male' THEN 1 END) AS male_count,
        COUNT(CASE WHEN p.gender = 'female' THEN 1 END) AS female_count
    FROM person p
    JOIN place c
      ON p.location_city_id = c.id
    JOIN place r
      ON c.part_of_place_id = r.id
    GROUP BY c.id, c.name, r.id, r.name
)
SELECT
    region_name,
    city_name,
    person_count,
    distinct_browser_count,
    male_count,
    female_count
FROM (
    SELECT
        city_id,
        city_name,
        region_id,
        region_name,
        person_count,
        distinct_browser_count,
        male_count,
        female_count,
        ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY person_count DESC) AS rn
    FROM city_agg
) ranked_cities
WHERE rn = 1
ORDER BY person_count DESC
LIMIT 10
