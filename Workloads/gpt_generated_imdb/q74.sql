WITH rating_per_movie AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS total_cast,
           COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
           COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
)
SELECT t.title,
       t.production_year,
       cc.total_cast,
       cc.male_cast,
       cc.female_cast,
       r.rating
FROM title t
JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN rating_per_movie r ON r.movie_id = t.id
WHERE t.kind_id = 1
  AND t.production_year >= 2000
ORDER BY cc.total_cast DESC,
         r.rating DESC
LIMIT 20
