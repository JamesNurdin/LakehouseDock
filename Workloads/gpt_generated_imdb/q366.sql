WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT cn.id) AS company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON cn.id = mc.company_id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    genre,
    production_year,
    COUNT(*) AS movie_count,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(company_count) AS avg_companies_per_movie
FROM movie_stats
GROUP BY genre, production_year
ORDER BY genre, production_year
