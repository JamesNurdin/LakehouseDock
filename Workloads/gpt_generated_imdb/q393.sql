WITH kind_notes AS (
    SELECT
        kt.kind AS kind,
        COUNT(DISTINCT t.id) AS num_titles,
        AVG(t.production_year) AS avg_production_year,
        AVG(mi.note) AS avg_note,
        approx_percentile(mi.note, 0.5) AS median_note,
        COUNT(mi.note) AS num_notes
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_info_idx mi ON mi.movie_id = t.id AND mi.info_type_id = 1
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
    GROUP BY kt.kind
)
SELECT
    kind,
    num_titles,
    avg_production_year,
    avg_note,
    median_note,
    num_notes,
    ROW_NUMBER() OVER (ORDER BY avg_note DESC) AS rank_by_avg_note
FROM kind_notes
ORDER BY rank_by_avg_note
