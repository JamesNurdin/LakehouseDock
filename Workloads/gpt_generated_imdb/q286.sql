WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        COUNT(DISTINCT k.id) AS distinct_keywords,
        MIN(t.production_year) AS first_movie_year,
        MAX(t.production_year) AS last_movie_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY n.id, n.name
)
SELECT
    person_id,
    person_name,
    movie_count,
    distinct_characters,
    distinct_keywords,
    first_movie_year,
    last_movie_year,
    ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
FROM person_stats
ORDER BY rank
LIMIT 10
