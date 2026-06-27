WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),
movie_keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
movie_company_info AS (
    SELECT
        t.id AS movie_id,
        ct.kind AS company_type,
        cn.name AS company_name
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production' AND t.production_year >= 2000
)
SELECT
    mc.production_year,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(mk.keyword_count) AS avg_keywords_per_movie,
    COUNT(DISTINCT ci.company_name) AS distinct_production_companies
FROM movie_cast_counts mc
LEFT JOIN movie_keyword_counts mk ON mk.movie_id = mc.movie_id
LEFT JOIN movie_company_info ci ON ci.movie_id = mc.movie_id
GROUP BY mc.production_year
ORDER BY mc.production_year
