WITH rating_per_movie AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
keyword_cnt_per_movie AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
cast_cnt_per_movie AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_cnt_per_movie AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(r.rating) AS avg_rating,
    AVG(kc.keyword_cnt) AS avg_keywords_per_movie,
    AVG(cc.cast_cnt) AS avg_cast_per_movie,
    AVG(compc.company_cnt) AS avg_companies_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN rating_per_movie r ON t.id = r.movie_id
LEFT JOIN keyword_cnt_per_movie kc ON t.id = kc.movie_id
LEFT JOIN cast_cnt_per_movie cc ON t.id = cc.movie_id
LEFT JOIN company_cnt_per_movie compc ON t.id = compc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY avg_rating DESC NULLS LAST, total_movies DESC
LIMIT 20
