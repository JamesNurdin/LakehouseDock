WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_per_movie AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    kt.kind AS kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_cnt) AS avg_cast_per_title,
    AVG(kc.kw_cnt) AS avg_keywords_per_title,
    AVG(rpm.rating) AS avg_rating
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN rating_per_movie rpm ON t.id = rpm.movie_id
GROUP BY kt.kind
ORDER BY movie_count DESC
LIMIT 10
