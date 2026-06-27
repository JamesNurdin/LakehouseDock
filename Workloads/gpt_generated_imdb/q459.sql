WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_company_count,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS rating
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
ranked_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        kind,
        cast_count,
        keyword_count,
        production_company_count,
        rating,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast
    FROM movie_stats
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    cast_count,
    keyword_count,
    production_company_count,
    rating,
    rank_by_cast
FROM ranked_movies
WHERE rank_by_cast <= 5
ORDER BY production_year, rank_by_cast
