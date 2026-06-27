WITH actor_movie_info AS (
    SELECT
        ci.person_id,
        n.name AS actor_name,
        ci.movie_id,
        t.production_year,
        kt.kind AS genre,
        ch.id AS character_id,
        cn.id AS company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN char_name ch ON ci.person_role_id = ch.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year >= 2000
),
actor_aggregates AS (
    SELECT
        person_id,
        actor_name,
        COUNT(DISTINCT movie_id) AS total_movies,
        MIN(production_year) AS earliest_year,
        MAX(production_year) AS latest_year,
        COUNT(DISTINCT character_id) AS distinct_characters,
        COUNT(DISTINCT CASE WHEN company_type = 'production' THEN company_id END) AS distinct_production_companies
    FROM actor_movie_info
    GROUP BY person_id, actor_name
    HAVING COUNT(DISTINCT movie_id) >= 5
),
actor_genre_counts AS (
    SELECT
        person_id,
        genre,
        COUNT(DISTINCT movie_id) AS genre_movie_count
    FROM actor_movie_info
    GROUP BY person_id, genre
),
actor_top_genre AS (
    SELECT
        person_id,
        genre,
        genre_movie_count,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY genre_movie_count DESC) AS rn
    FROM actor_genre_counts
)
SELECT
    a.actor_name,
    a.total_movies,
    a.earliest_year,
    a.latest_year,
    a.distinct_characters,
    a.distinct_production_companies,
    tg.genre AS top_genre,
    tg.genre_movie_count AS top_genre_movie_count
FROM actor_aggregates a
JOIN actor_top_genre tg
    ON a.person_id = tg.person_id
WHERE tg.rn = 1
ORDER BY a.total_movies DESC, a.actor_name
LIMIT 100
