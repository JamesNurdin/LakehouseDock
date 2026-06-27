WITH movie_stats AS (
    SELECT
        title.id AS movie_id,
        title.title,
        title.production_year,
        kind_type.kind AS genre,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        COUNT(DISTINCT movie_companies.company_id) AS company_count,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count,
        COUNT(DISTINCT movie_info.id) AS info_count
    FROM title
    JOIN kind_type
        ON title.kind_id = kind_type.id
    LEFT JOIN cast_info
        ON cast_info.movie_id = title.id
    LEFT JOIN movie_companies
        ON movie_companies.movie_id = title.id
    LEFT JOIN movie_keyword
        ON movie_keyword.movie_id = title.id
    LEFT JOIN movie_info
        ON movie_info.movie_id = title.id
    WHERE title.production_year >= 2000
    GROUP BY title.id, title.title, title.production_year, kind_type.kind
)
SELECT
    movie_id,
    title,
    production_year,
    genre,
    cast_count,
    company_count,
    keyword_count,
    info_count,
    RANK() OVER (PARTITION BY genre ORDER BY cast_count DESC) AS rank_in_genre
FROM movie_stats
ORDER BY genre, rank_in_genre
LIMIT 50
