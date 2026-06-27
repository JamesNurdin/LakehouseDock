WITH actor_movies AS (
    SELECT
        ci.person_id,
        n.name AS actor_name,
        ci.movie_id,
        t.title AS movie_title,
        t.production_year,
        cn.name AS character_name
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year BETWEEN 2000 AND 2010
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(*) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
actor_keyword_stats AS (
    SELECT
        am.person_id,
        am.actor_name,
        COUNT(DISTINCT am.movie_id) AS movie_cnt,
        AVG(COALESCE(kc.kw_cnt, 0)) AS avg_keywords_per_movie
    FROM actor_movies am
    LEFT JOIN keyword_counts kc ON am.movie_id = kc.movie_id
    GROUP BY am.person_id, am.actor_name
),
actor_char_counts AS (
    SELECT
        am.person_id,
        am.character_name,
        COUNT(*) AS cnt
    FROM actor_movies am
    WHERE am.character_name IS NOT NULL
    GROUP BY am.person_id, am.character_name
),
actor_top_character AS (
    SELECT
        person_id,
        character_name
    FROM (
        SELECT
            person_id,
            character_name,
            ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY cnt DESC) AS rn
        FROM actor_char_counts
    ) sub
    WHERE rn = 1
)
SELECT
    aks.person_id,
    aks.actor_name,
    aks.movie_cnt,
    COALESCE(atc.character_name, 'N/A') AS top_character,
    ROUND(aks.avg_keywords_per_movie, 2) AS avg_keywords_per_movie
FROM actor_keyword_stats aks
LEFT JOIN actor_top_character atc ON aks.person_id = atc.person_id
ORDER BY aks.movie_cnt DESC
LIMIT 10
