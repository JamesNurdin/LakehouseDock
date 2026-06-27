WITH person_aggregates AS (
    SELECT
        name.id AS person_id,
        name.gender,
        COUNT(DISTINCT aka_name.id) AS aka_name_count,
        COUNT(DISTINCT person_info.info_type_id) AS info_type_count
    FROM name
    LEFT JOIN aka_name
        ON aka_name.person_id = name.id
    LEFT JOIN person_info
        ON person_info.person_id = name.id
    WHERE name.gender IS NOT NULL
    GROUP BY name.id, name.gender
)
SELECT
    gender,
    COUNT(*) AS person_count,
    AVG(aka_name_count) AS avg_aka_names_per_person,
    AVG(info_type_count) AS avg_info_types_per_person
FROM person_aggregates
GROUP BY gender
ORDER BY person_count DESC
