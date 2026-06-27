WITH keyword_counts AS (
    SELECT
        kind_type.kind AS kind,
        keyword.keyword AS keyword,
        COUNT(DISTINCT title.id) AS title_count
    FROM movie_keyword
    JOIN title
        ON movie_keyword.movie_id = title.id
    JOIN keyword
        ON movie_keyword.keyword_id = keyword.id
    JOIN kind_type
        ON title.kind_id = kind_type.id
    WHERE title.production_year BETWEEN 2000 AND 2020
    GROUP BY kind_type.kind, keyword.keyword
),
ranked_keywords AS (
    SELECT
        kind,
        keyword,
        title_count,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY title_count DESC) AS rn
    FROM keyword_counts
)
SELECT
    kind,
    keyword,
    title_count
FROM ranked_keywords
WHERE rn <= 10
ORDER BY kind, title_count DESC
