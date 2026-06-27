WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.title,
        CAST(t.production_year AS integer) AS prod_year,
        kt.kind,
        COUNT(DISTINCT n.id) AS num_cast,
        COUNT(DISTINCT cn.id) AS num_characters
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, CAST(t.production_year AS integer), kt.kind
)
SELECT
    title,
    prod_year,
    kind,
    num_cast,
    num_characters
FROM movie_cast
ORDER BY num_cast DESC, num_characters DESC
LIMIT 10
