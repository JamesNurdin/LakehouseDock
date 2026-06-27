WITH cast_counts AS (
    SELECT
        cast_info.movie_id AS movie_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_member_count
    FROM cast_info
    GROUP BY cast_info.movie_id
),
keyword_counts AS (
    SELECT
        movie_keyword.movie_id AS movie_id,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_keyword.movie_id
),
rating_info AS (
    SELECT
        movie_info.movie_id AS movie_id,
        AVG(CAST(movie_info.info AS DOUBLE)) AS avg_rating
    FROM movie_info
    JOIN info_type ON movie_info.info_type_id = info_type.id
    WHERE info_type.info = 'rating'
    GROUP BY movie_info.movie_id
)
SELECT
    title.title,
    title.production_year,
    kind_type.kind,
    COALESCE(cast_counts.cast_member_count, 0) AS cast_member_count,
    COALESCE(keyword_counts.keyword_count, 0) AS keyword_count,
    rating_info.avg_rating
FROM title
JOIN kind_type ON title.kind_id = kind_type.id
LEFT JOIN cast_counts ON cast_counts.movie_id = title.id
LEFT JOIN keyword_counts ON keyword_counts.movie_id = title.id
LEFT JOIN rating_info ON rating_info.movie_id = title.id
WHERE title.production_year >= 2000
ORDER BY rating_info.avg_rating DESC NULLS LAST
LIMIT 20
