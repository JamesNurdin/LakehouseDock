WITH movie_details AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        c.person_id,
        n.name AS person_name,
        cn.name AS character_name,
        mi.id AS movie_info_id,
        it.info AS info_type,
        mi.info AS info_detail
    FROM title t
    JOIN cast_info c
        ON c.movie_id = t.id
    JOIN name n
        ON n.id = c.person_id
    LEFT JOIN char_name cn
        ON cn.id = c.person_role_id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON it.id = mi.info_type_id
    WHERE t.kind_id = 1
      AND t.production_year >= 2000
)
SELECT
    md.title,
    md.production_year,
    COUNT(DISTINCT md.person_id) AS num_actors,
    COUNT(DISTINCT md.character_name) AS num_characters,
    COUNT(DISTINCT CASE WHEN md.info_type = 'Trivia' THEN md.movie_info_id END) AS num_trivia_entries
FROM movie_details md
GROUP BY md.title, md.production_year
ORDER BY num_actors DESC
LIMIT 10
