WITH title_kind AS (
    SELECT t.id AS title_id,
           t.title,
           k.kind,
           t.production_year
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
)
SELECT
    tk.kind,
    it.info,
    COUNT(DISTINCT tk.title_id) AS title_count,
    AVG(mi_idx.note) AS avg_note,
    AVG(tk.production_year) AS avg_production_year,
    COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_count
FROM title_kind tk
LEFT JOIN movie_info_idx mi_idx ON mi_idx.movie_id = tk.title_id
LEFT JOIN info_type it ON mi_idx.info_type_id = it.id
LEFT JOIN movie_keyword mk ON mk.movie_id = tk.title_id
GROUP BY tk.kind, it.info
ORDER BY tk.kind, title_count DESC
