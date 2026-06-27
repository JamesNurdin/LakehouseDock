WITH cast_counts AS (
        SELECT ci.movie_id,
               COUNT(DISTINCT ci.person_id) AS cast_count,
               COUNT(DISTINCT ci.person_role_id) AS distinct_roles
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_counts AS (
        SELECT mc.movie_id,
               COUNT(DISTINCT mc.company_id) AS company_count,
               COUNT(DISTINCT mc.company_type_id) AS company_type_count
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    rating_info AS (
        SELECT mi.movie_id,
               AVG(CAST(mi.info AS double)) AS avg_rating
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'rating'
        GROUP BY mi.movie_id
    ),
    keyword_counts AS (
        SELECT mk.movie_id,
               COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    )
SELECT t.title,
       t.production_year,
       kt.kind,
       COALESCE(cc.cast_count, 0)            AS cast_count,
       COALESCE(cc.distinct_roles, 0)        AS distinct_roles,
       COALESCE(comc.company_count, 0)       AS company_count,
       COALESCE(comc.company_type_count, 0)  AS company_type_count,
       ri.avg_rating,
       COALESCE(kc.keyword_count, 0)         AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc      ON t.id = cc.movie_id
LEFT JOIN company_counts comc ON t.id = comc.movie_id
LEFT JOIN rating_info ri      ON t.id = ri.movie_id
LEFT JOIN keyword_counts kc   ON t.id = kc.movie_id
WHERE t.production_year = 2010
ORDER BY cast_count DESC, avg_rating DESC
LIMIT 100
