WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast,
        COUNT(DISTINCT cn.id) AS character_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN name n ON n.id = ci.person_id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    WHERE t.production_year IS NOT NULL
      AND n.gender IN ('M', 'F')
    GROUP BY t.id, t.production_year
)
SELECT
    production_year,
    COUNT(*) AS movie_count,
    AVG(total_cast) AS avg_cast_per_movie,
    AVG(male_cast) AS avg_male_cast_per_movie,
    AVG(female_cast) AS avg_female_cast_per_movie,
    AVG(character_count) AS avg_characters_per_movie,
    SUM(CASE WHEN female_cast > male_cast THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_movies_female_majority
FROM movie_details
GROUP BY production_year
ORDER BY production_year DESC
