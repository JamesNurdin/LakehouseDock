WITH keyword_counts AS (
    SELECT
        t.production_year,
        k.keyword,
        COUNT(DISTINCT t.id) AS movie_count
    FROM title AS t
    JOIN kind_type AS kt
        ON t.kind_id = kt.id
    JOIN movie_keyword AS mk
        ON mk.movie_id = t.id
    JOIN keyword AS k
        ON mk.keyword_id = k.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year, k.keyword
)
SELECT
    production_year,
    keyword,
    movie_count
FROM (
    SELECT
        production_year,
        keyword,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM keyword_counts
) AS ranked
WHERE rn <= 5
ORDER BY production_year ASC, movie_count DESC
