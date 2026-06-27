WITH actor_movies AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        cn.name AS character_name,
        mi.info AS movie_budget
    FROM cast_info c
    JOIN name n ON c.person_id = n.id
    JOIN title t ON c.movie_id = t.id
    LEFT JOIN char_name cn ON c.person_role_id = cn.id
    LEFT JOIN movie_info_idx mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id AND it.info = 'budget'
    WHERE t.production_year BETWEEN 1990 AND 1999
      AND t.kind_id = 1
),
person_info_counts AS (
    SELECT
        pi.person_id,
        COUNT(*) AS info_entry_count
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    am.person_name,
    am.gender,
    COUNT(DISTINCT am.movie_id) AS distinct_movies,
    COUNT(DISTINCT am.character_name) AS distinct_characters,
    AVG(TRY_CAST(am.movie_budget AS DOUBLE)) AS avg_movie_budget,
    COALESCE(pic.info_entry_count, 0) AS person_info_entries
FROM actor_movies am
LEFT JOIN person_info_counts pic ON am.person_id = pic.person_id
GROUP BY am.person_name, am.gender, COALESCE(pic.info_entry_count, 0)
ORDER BY distinct_movies DESC
LIMIT 10
