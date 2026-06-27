WITH movie_cast_stats AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        kt.kind AS kind,
        t.production_year,
        COUNT(DISTINCT n.id) AS distinct_cast_members,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        SUM(ci.nr_order) AS total_cast_order,
        COUNT(DISTINCT mc.company_id) AS distinct_companies
    FROM
        cast_info ci
        JOIN name n ON ci.person_id = n.id
        JOIN title t ON ci.movie_id = t.id
        JOIN kind_type kt ON t.kind_id = kt.id
        LEFT JOIN char_name cn ON ci.person_role_id = cn.id
        LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id,
        t.title,
        kt.kind,
        t.production_year
)
SELECT
    movie_title,
    kind,
    production_year,
    distinct_cast_members,
    distinct_characters,
    total_cast_order,
    distinct_companies
FROM movie_cast_stats
ORDER BY distinct_cast_members DESC
LIMIT 10
