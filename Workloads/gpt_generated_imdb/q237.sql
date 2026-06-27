WITH ranked_info AS (
    SELECT
        mi.movie_id,
        it.info AS info_type,
        mi.note,
        mi.info AS info_value,
        ROW_NUMBER() OVER (PARTITION BY it.info ORDER BY mi.note DESC) AS rn
    FROM movie_info_idx mi
    JOIN info_type it
      ON mi.info_type_id = it.id
)
SELECT
    info_type,
    movie_id,
    note,
    info_value
FROM ranked_info
WHERE rn <= 3
ORDER BY info_type, note DESC
