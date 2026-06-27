WITH drama_movies AS (
    SELECT t.id AS movie_id
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'genre' AND lower(mi.info) = 'drama'
),
actor_drama_counts AS (
    SELECT ci.person_id,
           COUNT(DISTINCT ci.movie_id) AS drama_movie_count
    FROM cast_info ci
    JOIN drama_movies dm ON dm.movie_id = ci.movie_id
    GROUP BY ci.person_id
),
aka_name_counts AS (
    SELECT an.person_id,
           COUNT(*) AS aka_name_count
    FROM aka_name an
    GROUP BY an.person_id
)
SELECT n.id AS person_id,
       n.name,
       COALESCE(aka.aka_name_count, 0) AS aka_name_count,
       COALESCE(ad.drama_movie_count, 0) AS drama_movie_count
FROM name n
LEFT JOIN actor_drama_counts ad ON ad.person_id = n.id
LEFT JOIN aka_name_counts aka ON aka.person_id = n.id
WHERE COALESCE(ad.drama_movie_count, 0) > 0
ORDER BY drama_movie_count DESC, aka_name_count DESC
LIMIT 10
