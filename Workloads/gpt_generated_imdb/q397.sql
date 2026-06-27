SELECT
  it.info AS info_type,
  (
    SELECT COUNT(*)
    FROM movie_info mi
    WHERE mi.info_type_id = it.id
  ) AS movie_info_cnt,
  (
    SELECT COUNT(*)
    FROM person_info pi
    WHERE pi.info_type_id = it.id
  ) AS person_info_cnt,
  (
    SELECT COUNT(*)
    FROM movie_info_idx mi_idx
    WHERE mi_idx.info_type_id = it.id
  ) AS movie_info_idx_cnt,
  (
    SELECT SUM(mi_idx.note)
    FROM movie_info_idx mi_idx
    WHERE mi_idx.info_type_id = it.id
  ) AS movie_info_idx_note_sum,
  (
    SELECT t.title
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    WHERE mi.info_type_id = it.id
    GROUP BY t.title
    ORDER BY COUNT(*) DESC
    LIMIT 1
  ) AS top_movie_title,
  (
    SELECT COUNT(*)
    FROM movie_info mi
    JOIN title t ON mi.movie_id = t.id
    WHERE mi.info_type_id = it.id
    GROUP BY t.title
    ORDER BY COUNT(*) DESC
    LIMIT 1
  ) AS top_movie_info_cnt
FROM info_type it
ORDER BY movie_info_cnt DESC
LIMIT 20
