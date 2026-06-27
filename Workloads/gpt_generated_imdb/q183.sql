WITH per_movie AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS num_movies,
    SUM(cast_count) AS total_cast_members,
    AVG(cast_count) AS avg_cast_per_movie,
    SUM(keyword_count) AS total_keywords,
    AVG(keyword_count) AS avg_keywords_per_movie,
    SUM(company_count) AS total_companies,
    AVG(company_count) AS avg_companies_per_movie
FROM per_movie
GROUP BY production_year, kind
ORDER BY production_year, kind
