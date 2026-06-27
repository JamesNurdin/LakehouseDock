WITH
    cast_counts AS (
        SELECT
            title.id AS movie_id,
            COUNT(DISTINCT cast_info.person_id) AS cast_member_count
        FROM cast_info
        JOIN title
            ON cast_info.movie_id = title.id
        GROUP BY title.id
    ),
    company_counts AS (
        SELECT
            title.id AS movie_id,
            COUNT(DISTINCT movie_companies.company_id) AS company_count
        FROM movie_companies
        JOIN title
            ON movie_companies.movie_id = title.id
        GROUP BY title.id
    ),
    genre_agg AS (
        SELECT
            title.id AS movie_id,
            array_agg(DISTINCT movie_info.info) FILTER (WHERE info_type.info = 'genre') AS genres
        FROM movie_info
        JOIN info_type
            ON movie_info.info_type_id = info_type.id
        JOIN title
            ON movie_info.movie_id = title.id
        GROUP BY title.id
    )
SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    g.genres,
    c.cast_member_count,
    co.company_count
FROM title t
LEFT JOIN cast_counts c
    ON c.movie_id = t.id
LEFT JOIN company_counts co
    ON co.movie_id = t.id
LEFT JOIN genre_agg g
    ON g.movie_id = t.id
ORDER BY c.cast_member_count DESC NULLS LAST
LIMIT 10
