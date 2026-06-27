/*
  Analytical query: for each gender, compute the number of persons,
  total alternative (aka) names, average aka names per person, and
  how many persons have at least one aka name.
*/
WITH person_aka_counts AS (
    SELECT
        name.id AS person_id,
        name.gender,
        COUNT(aka_name.id) AS aka_name_count
    FROM name
    LEFT JOIN aka_name
        ON aka_name.person_id = name.id
    GROUP BY name.id, name.gender
)
SELECT
    gender,
    COUNT(person_id) AS person_count,
    SUM(aka_name_count) AS total_aka_names,
    AVG(aka_name_count) AS avg_aka_per_person,
    COUNT(CASE WHEN aka_name_count > 0 THEN 1 END) AS persons_with_aka
FROM person_aka_counts
GROUP BY gender
ORDER BY avg_aka_per_person DESC
