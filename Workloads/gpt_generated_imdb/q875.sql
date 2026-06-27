WITH movie_genre AS (
    SELECT
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        mi.info AS genre
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'genre'
)
SELECT
    mg.movie_title,
    mg.production_year,
    mg.kind_id,
    mg.genre,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN n.gender = 'M' THEN 1 ELSE 0 END) AS male_cast,
    SUM(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
    AVG(aka_counts.aka_count) AS avg_aka_names_per_cast
FROM movie_genre mg
JOIN cast_info ci ON ci.movie_id = mg.title_id
JOIN name n ON n.id = ci.person_id
LEFT JOIN (
    SELECT
        an.person_id,
        COUNT(*) AS aka_count
    FROM aka_name an
    GROUP BY an.person_id
) aka_counts ON aka_counts.person_id = n.id
WHERE mg.genre = 'Drama'
GROUP BY mg.movie_title, mg.production_year, mg.kind_id, mg.genre
ORDER BY total_cast DESC
LIMIT 10
