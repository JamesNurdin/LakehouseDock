WITH movie_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_ratings AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
      AND mi.info IS NOT NULL
    GROUP BY mi.movie_id
),
movie_keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    kt.kind AS movie_kind,
    COUNT(*) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    AVG(mr.rating) AS avg_rating,
    SUM(COALESCE(mcc.company_cnt, 0)) AS total_company_counts,
    AVG(COALESCE(mcc.company_cnt, 0)) AS avg_company_per_movie,
    SUM(COALESCE(mct.cast_cnt, 0)) AS total_cast_counts,
    AVG(COALESCE(mct.cast_cnt, 0)) AS avg_cast_per_movie,
    SUM(COALESCE(mkc.keyword_cnt, 0)) AS total_keyword_counts,
    AVG(COALESCE(mkc.keyword_cnt, 0)) AS avg_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_company_counts mcc ON mcc.movie_id = t.id
LEFT JOIN movie_cast_counts mct ON mct.movie_id = t.id
LEFT JOIN movie_ratings mr ON mr.movie_id = t.id
LEFT JOIN movie_keyword_counts mkc ON mkc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind
ORDER BY movie_count DESC
LIMIT 10
