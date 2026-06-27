WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_per_movie AS (
    SELECT mi.movie_id,
           AVG(TRY_CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE LOWER(it.info) = 'rating'
    GROUP BY mi.movie_id
)
SELECT kt.kind AS movie_kind,
       t.production_year,
       COUNT(DISTINCT t.id) AS movie_count,
       AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_per_movie,
       AVG(COALESCE(compc.company_cnt, 0)) AS avg_companies_per_movie,
       AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie,
       AVG(COALESCE(r.avg_rating, 0)) AS avg_rating_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN rating_per_movie r ON t.id = r.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY movie_count DESC
LIMIT 20
