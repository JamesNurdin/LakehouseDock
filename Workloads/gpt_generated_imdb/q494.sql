WITH movie_ratings AS (
    SELECT
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        kind_type.kind AS kind,
        CAST(movie_info.info AS double) AS rating
    FROM title
    JOIN kind_type ON title.kind_id = kind_type.id
    JOIN movie_info ON movie_info.movie_id = title.id
    JOIN info_type ON movie_info.info_type_id = info_type.id
    WHERE info_type.info = 'rating'
      AND title.production_year IS NOT NULL
),
actor_counts AS (
    SELECT
        cast_info.movie_id AS movie_id,
        COUNT(DISTINCT cast_info.person_id) AS actor_count
    FROM cast_info
    GROUP BY cast_info.movie_id
),
production_company_counts AS (
    SELECT
        movie_companies.movie_id AS movie_id,
        COUNT(DISTINCT movie_companies.company_id) AS prod_company_count
    FROM movie_companies
    JOIN company_type ON movie_companies.company_type_id = company_type.id
    WHERE company_type.kind = 'production'
    GROUP BY movie_companies.movie_id
),
keyword_counts AS (
    SELECT
        movie_keyword.movie_id AS movie_id,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_keyword.movie_id
)
SELECT
    mr.movie_title,
    mr.production_year,
    mr.kind,
    mr.rating,
    ac.actor_count,
    pcc.prod_company_count,
    kc.keyword_count
FROM movie_ratings mr
LEFT JOIN actor_counts ac ON mr.movie_id = ac.movie_id
LEFT JOIN production_company_counts pcc ON mr.movie_id = pcc.movie_id
LEFT JOIN keyword_counts kc ON mr.movie_id = kc.movie_id
WHERE mr.kind = 'movie'
ORDER BY mr.rating DESC
LIMIT 10
