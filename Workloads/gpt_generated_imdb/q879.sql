WITH movie_gender_stats AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        n.gender,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT cn.id) AS character_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN name n ON n.id = ci.person_id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.production_year, n.gender
)
SELECT
    mgs.production_year,
    mgs.gender,
    COUNT(*) AS movies_count,
    SUM(mgs.actor_count) AS total_actors,
    SUM(mgs.character_count) AS total_characters,
    SUM(mgs.keyword_count) AS total_keywords,
    AVG(mgs.actor_count) AS avg_actors_per_movie,
    AVG(mgs.character_count) AS avg_characters_per_movie,
    AVG(mgs.keyword_count) AS avg_keywords_per_movie
FROM movie_gender_stats mgs
GROUP BY mgs.production_year, mgs.gender
ORDER BY mgs.production_year, mgs.gender
