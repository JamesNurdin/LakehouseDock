/*
  Top 10 fictional characters that appear in movies released from the year 2000 onward.
  For each character we report:
    • The number of distinct movies the character appears in.
    • The number of distinct actors who have portrayed the character.
    • The average role order (nr_order) across all appearances.
  The query follows the allowed join rules and uses only the listed tables/columns.
*/
WITH char_stats AS (
    SELECT
        cn.name AS character_name,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT ci.person_id) AS distinct_actor_count,
        AVG(ci.nr_order) AS avg_role_order
    FROM cast_info ci
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    JOIN title t
        ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY cn.name
)
SELECT
    character_name,
    movie_count,
    distinct_actor_count,
    avg_role_order
FROM char_stats
ORDER BY movie_count DESC, distinct_actor_count DESC
LIMIT 10
