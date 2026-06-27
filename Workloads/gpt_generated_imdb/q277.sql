WITH cast_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           COUNT(DISTINCT ci.person_role_id) AS character_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_agg AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS double)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT t.title,
       t.production_year,
       ca.cast_count,
       ca.character_count,
       COALESCE(ka.keyword_count, 0) AS keyword_count,
       ra.avg_rating
FROM title t
JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN keyword_agg ka ON ka.movie_id = t.id
LEFT JOIN rating_agg ra ON ra.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY ca.cast_count DESC
LIMIT 10
