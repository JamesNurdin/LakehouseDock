WITH movie_genres AS (
    SELECT mi.movie_id,
           mi.info AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
)
SELECT
    t.title,
    t.production_year,
    g.genre,
    COUNT(DISTINCT n.id) AS distinct_cast,
    COUNT(DISTINCT cn.id) AS distinct_characters,
    CAST(COUNT(DISTINCT cn.id) AS double) / NULLIF(COUNT(DISTINCT n.id), 0) AS avg_characters_per_cast
FROM title t
JOIN cast_info ci ON ci.movie_id = t.id
JOIN name n ON ci.person_id = n.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
LEFT JOIN movie_genres g ON g.movie_id = t.id
WHERE t.production_year >= 2000
  AND g.genre IS NOT NULL
GROUP BY t.title, t.production_year, g.genre
ORDER BY distinct_cast DESC
LIMIT 10
