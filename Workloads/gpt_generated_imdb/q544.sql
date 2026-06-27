WITH info_details AS (
    SELECT
        it.info AS info_type,
        mi.movie_id,
        mi.info AS info_text,
        mi.note AS note_text,
        length(mi.info) AS info_len,
        length(mi.note) AS note_len
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
)
SELECT
    info_type,
    count(DISTINCT movie_id) AS movie_count,
    count(*) AS total_entries,
    avg(info_len) AS avg_info_length,
    avg(note_len) AS avg_note_length,
    sum(CASE WHEN note_text IS NOT NULL THEN 1 ELSE 0 END) * 1.0 / count(*) AS note_presence_ratio
FROM info_details
GROUP BY info_type
ORDER BY total_entries DESC
