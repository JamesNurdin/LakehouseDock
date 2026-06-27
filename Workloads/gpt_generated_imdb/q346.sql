SELECT
    t.production_year,
    it.info AS info_type,
    mc.company_type_id,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT mi.id) AS info_entry_count,
    AVG(mi_idx.note) AS avg_info_idx_note
FROM title t
LEFT JOIN movie_companies mc
  ON mc.movie_id = t.id
LEFT JOIN movie_info mi
  ON mi.movie_id = t.id
LEFT JOIN info_type it
  ON mi.info_type_id = it.id
LEFT JOIN movie_info_idx mi_idx
  ON mi_idx.movie_id = t.id
  AND mi_idx.info_type_id = it.id
WHERE t.production_year >= 2000
GROUP BY t.production_year, it.info, mc.company_type_id
ORDER BY t.production_year DESC, it.info, mc.company_type_id
