WITH movie_note AS (
    SELECT movie_id,
           avg(note) AS avg_note
    FROM movie_info_idx
    GROUP BY movie_id
)
SELECT
    k.id AS keyword_id,
    k.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(mn.avg_note) AS avg_note_per_keyword,
    MIN(t.production_year) AS earliest_production_year,
    MAX(t.production_year) AS latest_production_year
FROM title t
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_note mn ON mn.movie_id = t.id
WHERE t.production_year >= 2000
  AND t.production_year < 2020
GROUP BY k.id, k.keyword
ORDER BY movie_count DESC
LIMIT 20
