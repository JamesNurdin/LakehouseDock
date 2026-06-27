WITH movie_cast_counts AS (
    SELECT
        title.id AS movie_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_cnt
    FROM cast_info
    JOIN title ON cast_info.movie_id = title.id
    GROUP BY title.id
),
keyword_agg AS (
    SELECT
        kind_type.kind,
        keyword.keyword,
        COUNT(DISTINCT title.id) AS movie_count,
        AVG(movie_cast_counts.cast_cnt) AS avg_cast_per_movie
    FROM title
    JOIN kind_type ON title.kind_id = kind_type.id
    JOIN movie_keyword ON movie_keyword.movie_id = title.id
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    JOIN movie_cast_counts ON movie_cast_counts.movie_id = title.id
    GROUP BY kind_type.kind, keyword.keyword
    HAVING COUNT(DISTINCT title.id) >= 10
),
ranked_keywords AS (
    SELECT
        kind,
        keyword,
        movie_count,
        avg_cast_per_movie,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY movie_count DESC) AS rank_per_kind
    FROM keyword_agg
)
SELECT
    kind,
    keyword,
    movie_count,
    avg_cast_per_movie
FROM ranked_keywords
WHERE rank_per_kind <= 5
ORDER BY kind, movie_count DESC
