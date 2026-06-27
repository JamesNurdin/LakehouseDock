WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
info_type3_flags AS (
    SELECT
        movie_id,
        MAX(CASE WHEN info_type_id = 3 THEN 1 ELSE 0 END) AS has_type3
    FROM movie_info
    GROUP BY movie_id
),
yearly_stats AS (
    SELECT
        t.production_year,
        COUNT(DISTINCT t.id) AS total_movies,
        SUM(COALESCE(it3.has_type3, 0)) AS movies_with_type3,
        AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
        AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie
    FROM title t
    LEFT JOIN cast_counts cc ON cc.movie_id = t.id
    LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
    LEFT JOIN info_type3_flags it3 ON it3.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
),
keyword_year_counts AS (
    SELECT
        t.production_year,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, k.keyword
),
top_keywords AS (
    SELECT
        production_year,
        keyword,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM keyword_year_counts
)
SELECT
    ys.production_year,
    ys.total_movies,
    ys.movies_with_type3,
    ROUND(ys.avg_cast_per_movie, 2) AS avg_cast_per_movie,
    ROUND(ys.avg_keywords_per_movie, 2) AS avg_keywords_per_movie,
    tk.keyword AS top_keyword,
    tk.movie_count AS top_keyword_movie_count
FROM yearly_stats ys
LEFT JOIN (
    SELECT production_year, keyword, movie_count
    FROM top_keywords
    WHERE rn = 1
) tk ON tk.production_year = ys.production_year
ORDER BY ys.production_year
