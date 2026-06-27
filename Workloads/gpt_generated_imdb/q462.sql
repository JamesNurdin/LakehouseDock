WITH movie_aggregates AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        kt.kind AS kind,
        t.production_year AS production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS character_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    GROUP BY
        t.id,
        t.title,
        kt.kind,
        t.production_year
),
ranked_movies AS (
    SELECT
        movie_title,
        kind,
        production_year,
        cast_count,
        character_count,
        company_count,
        keyword_count,
        info_type_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_in_year
    FROM movie_aggregates
)
SELECT
    movie_title,
    kind,
    production_year,
    cast_count,
    character_count,
    company_count,
    keyword_count,
    info_type_count,
    rank_in_year
FROM ranked_movies
WHERE rank_in_year <= 5
ORDER BY production_year DESC, rank_in_year
