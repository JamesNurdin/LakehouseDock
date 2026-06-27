WITH rating_info AS (
        SELECT mi.movie_id,
               avg(mi.note) AS avg_rating
        FROM movie_info_idx mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'rating'
        GROUP BY mi.movie_id
    ),
    cast_counts AS (
        SELECT ci.movie_id,
               count(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    keyword_counts AS (
        SELECT mk.movie_id,
               count(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    )
SELECT t.title,
       kt.kind,
       t.production_year,
       coalesce(cc.cast_count, 0)      AS cast_count,
       coalesce(kc.keyword_count, 0)   AS keyword_count,
       coalesce(r.avg_rating, 0)       AS avg_rating
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN rating_info r ON t.id = r.movie_id
WHERE t.production_year >= 2000
ORDER BY avg_rating DESC
LIMIT 10
