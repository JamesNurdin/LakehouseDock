WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2005
),
keyword_counts AS (
    SELECT
        m.production_year,
        k.keyword,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM movies m
    JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.production_year, k.keyword
),
ranked_keywords AS (
    SELECT
        production_year,
        keyword,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM keyword_counts
)
SELECT
    production_year,
    keyword,
    movie_count
FROM ranked_keywords
WHERE rn <= 10
ORDER BY production_year, movie_count DESC
