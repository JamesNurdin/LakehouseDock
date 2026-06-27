/*
   Analytical query: For each movie released from 2000 onward, compute the number of distinct actors,
   the breakdown by gender, the number of distinct characters played, and rank movies within each
   production year by total actor count.
*/
WITH movie_actor_stats AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_actor_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_actor_count,
        COUNT(DISTINCT cn.id) AS character_count
    FROM
        title t
        JOIN cast_info ci ON ci.movie_id = t.id
        JOIN name n ON n.id = ci.person_id
        LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id,
        t.title,
        t.production_year
)
SELECT
    movie_id,
    movie_title,
    production_year,
    actor_count,
    male_actor_count,
    female_actor_count,
    character_count,
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank_within_year
FROM movie_actor_stats
WHERE production_year >= 2000
ORDER BY production_year DESC, rank_within_year
LIMIT 20
