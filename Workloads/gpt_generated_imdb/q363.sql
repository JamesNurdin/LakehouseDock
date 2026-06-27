WITH movie_counts AS (
    SELECT t.kind_id AS kind_id,
           COUNT(*) AS movie_count
    FROM title t
    WHERE t.production_year >= 2000
    GROUP BY t.kind_id
),
keyword_counts AS (
    SELECT t.kind_id AS kind_id,
           COUNT(*) AS total_keywords
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.kind_id
),
info_counts AS (
    SELECT t.kind_id AS kind_id,
           COUNT(*) AS total_info_entries
    FROM movie_info mi
    JOIN title t ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.kind_id
),
info_idx_stats AS (
    SELECT t.kind_id AS kind_id,
           AVG(mi_idx.note) AS avg_note
    FROM movie_info_idx mi_idx
    JOIN title t ON mi_idx.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.kind_id
)
SELECT kt.kind,
       mc.movie_count,
       COALESCE(kc.total_keywords, 0) AS total_keywords,
       COALESCE(kc.total_keywords, 0) / NULLIF(mc.movie_count, 0) AS avg_keywords_per_movie,
       COALESCE(ic.total_info_entries, 0) AS total_info_entries,
       COALESCE(ic.total_info_entries, 0) / NULLIF(mc.movie_count, 0) AS avg_info_per_movie,
       COALESCE(ii.avg_note, 0) AS avg_info_idx_note
FROM kind_type kt
LEFT JOIN movie_counts mc ON kt.id = mc.kind_id
LEFT JOIN keyword_counts kc ON kt.id = kc.kind_id
LEFT JOIN info_counts ic ON kt.id = ic.kind_id
LEFT JOIN info_idx_stats ii ON kt.id = ii.kind_id
ORDER BY mc.movie_count DESC
LIMIT 10
