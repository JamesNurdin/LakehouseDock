WITH movie_cast_counts AS (
    SELECT
        cast_info.movie_id AS movie_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_cnt
    FROM cast_info
    GROUP BY cast_info.movie_id
),
movie_keyword_counts AS (
    SELECT
        movie_keyword.movie_id AS movie_id,
        COUNT(DISTINCT keyword.keyword) AS keyword_cnt
    FROM movie_keyword
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY movie_keyword.movie_id
)
SELECT
    title.production_year,
    kind_type.kind,
    COUNT(title.id) AS movie_count,
    COALESCE(SUM(movie_cast_counts.cast_cnt), 0) / NULLIF(COUNT(title.id), 0) AS avg_cast_per_movie,
    COALESCE(SUM(movie_keyword_counts.keyword_cnt), 0) AS total_keywords
FROM title
JOIN kind_type ON title.kind_id = kind_type.id
LEFT JOIN movie_cast_counts ON title.id = movie_cast_counts.movie_id
LEFT JOIN movie_keyword_counts ON title.id = movie_keyword_counts.movie_id
WHERE title.production_year >= 2000
GROUP BY title.production_year, kind_type.kind
ORDER BY title.production_year DESC, kind_type.kind
