WITH cast_counts AS (
    SELECT
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        kind_type.kind AS kind,
        COUNT(DISTINCT cast_info.person_id) AS cast_count
    FROM title
    JOIN kind_type ON title.kind_id = kind_type.id
    JOIN cast_info ON cast_info.movie_id = title.id
    GROUP BY title.id, title.title, title.production_year, kind_type.kind
), prod_company_counts AS (
    SELECT
        title.id AS movie_id,
        COUNT(DISTINCT company_name.id) AS prod_company_count
    FROM title
    JOIN movie_companies ON movie_companies.movie_id = title.id
    JOIN company_type ON movie_companies.company_type_id = company_type.id
    JOIN company_name ON movie_companies.company_id = company_name.id
    WHERE company_type.kind = 'production'
    GROUP BY title.id
), keyword_counts AS (
    SELECT
        title.id AS movie_id,
        COUNT(DISTINCT keyword.id) AS keyword_count
    FROM title
    JOIN movie_keyword ON movie_keyword.movie_id = title.id
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY title.id
), ratings AS (
    SELECT
        title.id AS movie_id,
        MAX(CAST(movie_info.info AS double)) AS rating
    FROM title
    JOIN movie_info ON movie_info.movie_id = title.id
    JOIN info_type ON movie_info.info_type_id = info_type.id
    WHERE info_type.info = 'rating'
    GROUP BY title.id
)
SELECT
    c.movie_id,
    c.movie_title,
    c.production_year,
    c.kind,
    c.cast_count,
    COALESCE(pc.prod_company_count, 0) AS prod_company_count,
    COALESCE(k.keyword_count, 0) AS keyword_count,
    r.rating
FROM cast_counts c
LEFT JOIN prod_company_counts pc ON c.movie_id = pc.movie_id
LEFT JOIN keyword_counts k ON c.movie_id = k.movie_id
LEFT JOIN ratings r ON c.movie_id = r.movie_id
ORDER BY c.cast_count DESC, r.rating DESC NULLS LAST
LIMIT 10
