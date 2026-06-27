WITH movie_aggregates AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.kind_id = 1
    GROUP BY t.id, t.production_year
),
year_stats AS (
    SELECT
        production_year,
        COUNT(*) AS total_movies,
        AVG(keyword_count) AS avg_keywords_per_movie,
        AVG(cast_count) AS avg_cast_per_movie,
        AVG(company_count) AS avg_companies_per_movie
    FROM movie_aggregates
    WHERE production_year IS NOT NULL
    GROUP BY production_year
),
keyword_frequencies AS (
    SELECT
        t.production_year,
        k.keyword,
        COUNT(*) AS freq
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.kind_id = 1
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year, k.keyword
),
top_keyword_per_year AS (
    SELECT
        production_year,
        max_by(keyword, freq) AS top_keyword
    FROM keyword_frequencies
    GROUP BY production_year
)
SELECT
    y.production_year,
    y.total_movies,
    y.avg_keywords_per_movie,
    y.avg_cast_per_movie,
    y.avg_companies_per_movie,
    t.top_keyword
FROM year_stats y
LEFT JOIN top_keyword_per_year t ON t.production_year = y.production_year
ORDER BY y.production_year DESC
