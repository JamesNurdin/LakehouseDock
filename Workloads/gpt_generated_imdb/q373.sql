WITH movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
),
movie_ratings AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    m.production_year,
    COUNT(DISTINCT m.movie_id) AS num_movies,
    AVG(r.rating) AS avg_rating,
    AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(compc.company_cnt, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie
FROM movies m
LEFT JOIN movie_ratings r ON m.movie_id = r.movie_id
LEFT JOIN movie_cast_counts cc ON m.movie_id = cc.movie_id
LEFT JOIN movie_company_counts compc ON m.movie_id = compc.movie_id
LEFT JOIN movie_keyword_counts kc ON m.movie_id = kc.movie_id
GROUP BY m.production_year
ORDER BY avg_rating DESC
LIMIT 10
