WITH cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT ci.role_id) AS distinct_roles,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    GROUP BY ci.movie_id
),
alt_name_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT a.id) AS distinct_alt_names
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    LEFT JOIN aka_name a ON a.person_id = n.id
    GROUP BY ci.movie_id
),
movie_info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_types
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    ca.cast_count,
    ca.distinct_roles,
    ca.avg_nr_order,
    an.distinct_alt_names,
    mi.distinct_info_types
FROM title t
LEFT JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN alt_name_agg an ON an.movie_id = t.id
LEFT JOIN movie_info_agg mi ON mi.movie_id = t.id
WHERE t.production_year BETWEEN 2000 AND 2020
ORDER BY ca.cast_count DESC
LIMIT 100
