WITH movie_genre AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        mi.info AS genre
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'genre'
      AND t.production_year >= 2000
),
cast_counts AS (
    SELECT
        mg.title_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast
    FROM cast_info ci
    JOIN name n ON n.id = ci.person_id
    JOIN movie_genre mg ON mg.title_id = ci.movie_id
    GROUP BY mg.title_id
)
SELECT
    mg.production_year,
    mg.genre,
    COUNT(DISTINCT mg.title_id) AS num_movies,
    SUM(cc.total_cast) AS total_cast_members,
    AVG(cc.total_cast) AS avg_cast_per_movie,
    SUM(cc.male_cast) AS total_male_cast,
    SUM(cc.female_cast) AS total_female_cast
FROM movie_genre mg
JOIN cast_counts cc ON cc.title_id = mg.title_id
GROUP BY mg.production_year, mg.genre
HAVING COUNT(DISTINCT mg.title_id) >= 5
ORDER BY mg.production_year DESC, total_cast_members DESC
