WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE kt.kind = 'movie'
    GROUP BY t.id, t.production_year
),
year_stats AS (
    SELECT
        production_year,
        COUNT(*) AS total_movies,
        AVG(cast_count) AS avg_cast_per_movie
    FROM movie_cast_counts
    GROUP BY production_year
),
keyword_counts AS (
    SELECT
        t.production_year,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_keyword_count
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE kt.kind = 'movie' AND t.production_year IS NOT NULL
    GROUP BY t.production_year, k.keyword
),
top_keywords AS (
    SELECT
        production_year,
        keyword,
        movie_keyword_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_keyword_count DESC) AS rn
    FROM keyword_counts
)
SELECT
    ys.production_year,
    ys.total_movies,
    ys.avg_cast_per_movie,
    tk.keyword,
    tk.movie_keyword_count
FROM year_stats ys
JOIN top_keywords tk ON tk.production_year = ys.production_year
WHERE tk.rn <= 3
ORDER BY ys.production_year, tk.movie_keyword_count DESC
