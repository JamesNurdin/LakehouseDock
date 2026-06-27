WITH actor_roles AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        t.title AS movie_title,
        t.production_year,
        cn.name AS character_name,
        an.name AS aka_name
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    WHERE t.production_year >= 2000
      AND t.kind_id = 1
),
actor_stats AS (
    SELECT
        ar.person_id,
        ar.person_name,
        COUNT(DISTINCT ar.movie_title) AS movie_count,
        COUNT(DISTINCT ar.character_name) AS character_count,
        MIN(ar.production_year) AS first_year,
        MAX(ar.production_year) AS last_year,
        MIN(ar.aka_name) AS sample_aka_name
    FROM actor_roles ar
    GROUP BY ar.person_id, ar.person_name
    HAVING COUNT(DISTINCT ar.character_name) >= 3
)
SELECT
    person_id,
    person_name,
    movie_count,
    character_count,
    first_year,
    last_year,
    sample_aka_name,
    ROW_NUMBER() OVER (ORDER BY character_count DESC, movie_count DESC) AS rank
FROM actor_stats
ORDER BY rank
LIMIT 100
