WITH person_movie_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS primary_name,
        n.gender,
        n.imdb_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(ci.role_id) AS avg_role_id
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    WHERE ci.note IS NOT NULL
    GROUP BY n.id, n.name, n.gender, n.imdb_id
),
aka_name_counts AS (
    SELECT
        an.person_id,
        COUNT(DISTINCT an.name) AS alt_name_count
    FROM aka_name an
    GROUP BY an.person_id
),
person_info_counts AS (
    SELECT
        pi.person_id,
        COUNT(DISTINCT pi.info_type_id) AS info_type_count
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    pms.person_id,
    pms.primary_name,
    pms.gender,
    pms.imdb_id,
    pms.movie_count,
    pms.avg_role_id,
    COALESCE(aka.alt_name_count, 0) AS alt_name_count,
    COALESCE(pinf.info_type_count, 0) AS info_type_count
FROM person_movie_stats pms
LEFT JOIN aka_name_counts aka ON aka.person_id = pms.person_id
LEFT JOIN person_info_counts pinf ON pinf.person_id = pms.person_id
WHERE pms.gender = 'M'
ORDER BY pms.movie_count DESC, pms.person_id
LIMIT 20
