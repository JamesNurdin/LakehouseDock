WITH person_movie_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(DISTINCT t.id) AS movie_count,
        MIN(t.production_year) AS first_year,
        COUNT(DISTINCT cn.id) AS role_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON t.id = ci.movie_id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    GROUP BY n.id, n.name, n.gender
),
person_aka_stats AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT a.id) AS aka_count
    FROM name n
    LEFT JOIN aka_name a ON a.person_id = n.id
    GROUP BY n.id
),
person_info_stats AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN person_info pi ON pi.person_id = n.id
    LEFT JOIN info_type it ON it.id = pi.info_type_id
    GROUP BY n.id
)
SELECT
    pms.person_id,
    pms.person_name,
    pms.gender,
    pms.movie_count,
    pms.first_year,
    pms.role_count,
    pas.aka_count,
    pis.info_count
FROM person_movie_stats pms
JOIN person_aka_stats pas ON pas.person_id = pms.person_id
JOIN person_info_stats pis ON pis.person_id = pms.person_id
WHERE pms.movie_count >= 5
ORDER BY pms.movie_count DESC, pms.person_name
LIMIT 20
