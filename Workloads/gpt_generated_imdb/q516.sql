WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        COUNT(DISTINCT cn.id) AS num_characters,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    row_number() OVER (ORDER BY num_actors DESC) AS rank,
    movie_id,
    title,
    production_year,
    kind,
    num_actors,
    num_characters,
    num_companies
FROM movie_stats
ORDER BY num_actors DESC
LIMIT 10
