/* Top 10 actors by number of distinct movies, with character count, earliest year, and associated keywords */
WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS character_count,
        MIN(t.production_year) AS earliest_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM name n
    JOIN cast_info ci
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword k
        ON mk.keyword_id = k.id
    GROUP BY n.id, n.name
)
SELECT
    person_id,
    person_name,
    movie_count,
    character_count,
    earliest_year,
    keywords
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC, person_name) AS rn
    FROM person_stats
) ps
WHERE rn <= 10
ORDER BY rn
