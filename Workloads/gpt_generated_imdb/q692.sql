WITH movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind AS kind_name
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
prod_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_rating AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS double)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT
    m.production_year,
    m.kind_name,
    COUNT(*) AS movie_count,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(pc.prod_company_count, 0)) AS avg_prod_companies_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(mr.avg_rating) AS avg_rating
FROM movies m
LEFT JOIN cast_counts cc ON m.movie_id = cc.movie_id
LEFT JOIN prod_company_counts pc ON m.movie_id = pc.movie_id
LEFT JOIN keyword_counts kc ON m.movie_id = kc.movie_id
LEFT JOIN movie_rating mr ON m.movie_id = mr.movie_id
WHERE m.production_year IS NOT NULL
GROUP BY m.production_year, m.kind_name
ORDER BY m.production_year, m.kind_name
