WITH movie_notes AS (
    SELECT
        movie_id,
        sum(note) AS total_note,
        count(*) AS note_count
    FROM movie_info_idx
    GROUP BY movie_id
)
SELECT
    k.keyword,
    count(DISTINCT t.id) AS total_movies,
    avg(t.production_year) AS avg_production_year,
    sum(mn.total_note) AS sum_note,
    sum(mn.note_count) AS note_entries,
    sum(mn.total_note) / nullif(sum(mn.note_count), 0) AS avg_note
FROM title t
JOIN movie_keyword mk
    ON mk.movie_id = t.id
JOIN keyword k
    ON k.id = mk.keyword_id
LEFT JOIN movie_notes mn
    ON mn.movie_id = t.id
GROUP BY k.keyword
ORDER BY total_movies DESC
LIMIT 10
