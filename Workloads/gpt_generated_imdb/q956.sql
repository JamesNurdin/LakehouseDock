WITH movie_info AS (
    SELECT
        mii.movie_id,
        it.info AS info_type,
        mii.note
    FROM movie_info_idx mii
    JOIN info_type it ON mii.info_type_id = it.id
    WHERE mii.note IS NOT NULL
),
movie_details AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id
    FROM title t
    WHERE t.kind_id = 1
      AND t.production_year >= 2000
)
SELECT
    md.title,
    md.production_year,
    mi.info_type,
    AVG(mi.note) AS avg_note,
    COUNT(*) AS note_count
FROM movie_info mi
JOIN movie_details md ON mi.movie_id = md.title_id
GROUP BY
    md.title,
    md.production_year,
    mi.info_type
HAVING COUNT(*) > 5
ORDER BY avg_note DESC
LIMIT 50
