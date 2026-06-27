WITH movie_cast_counts AS (
    SELECT ci.movie_id AS movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    GROUP BY ci.movie_id
),
movie_keyword_counts AS (
    SELECT mk.movie_id AS movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    GROUP BY mk.movie_id
),
movie_company_type_counts AS (
    SELECT mc.movie_id AS movie_id,
           COUNT(DISTINCT ct.kind) AS company_type_cnt
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind AS genre,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(cc.cast_cnt) AS avg_cast_per_movie,
    AVG(kc.keyword_cnt) AS avg_keywords_per_movie,
    AVG(cct.company_type_cnt) AS avg_company_types_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts cc ON t.id = cc.movie_id
LEFT JOIN movie_keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN movie_company_type_counts cct ON t.id = cct.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year, kt.kind
