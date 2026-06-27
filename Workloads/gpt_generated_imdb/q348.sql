WITH movie_info_agg AS (
    SELECT it.id AS info_type_id,
           COUNT(DISTINCT mi.movie_id) AS distinct_movie_cnt,
           COUNT(*) AS movie_entry_cnt
    FROM info_type AS it
    JOIN movie_info AS mi ON mi.info_type_id = it.id
    GROUP BY it.id
),
movie_info_idx_agg AS (
    SELECT it.id AS info_type_id,
           COUNT(DISTINCT mi_idx.movie_id) AS distinct_movie_idx_cnt,
           SUM(mi_idx.note) AS total_note_sum,
           SUM(mi_idx.note) / NULLIF(COUNT(*), 0) AS avg_note
    FROM info_type AS it
    JOIN movie_info_idx AS mi_idx ON mi_idx.info_type_id = it.id
    GROUP BY it.id
),
person_info_agg AS (
    SELECT it.id AS info_type_id,
           COUNT(DISTINCT pi.person_id) AS distinct_person_cnt,
           COUNT(*) AS person_entry_cnt
    FROM info_type AS it
    JOIN person_info AS pi ON pi.info_type_id = it.id
    GROUP BY it.id
)
SELECT it.id,
       it.info,
       COALESCE(mi_agg.distinct_movie_cnt, 0)        AS distinct_movie_cnt,
       COALESCE(mi_agg.movie_entry_cnt, 0)          AS movie_entry_cnt,
       COALESCE(mi_idx_agg.distinct_movie_idx_cnt, 0) AS distinct_movie_idx_cnt,
       COALESCE(mi_idx_agg.total_note_sum, 0)       AS total_note_sum,
       COALESCE(mi_idx_agg.avg_note, 0)             AS avg_note,
       COALESCE(pi_agg.distinct_person_cnt, 0)      AS distinct_person_cnt,
       COALESCE(pi_agg.person_entry_cnt, 0)         AS person_entry_cnt
FROM info_type AS it
LEFT JOIN movie_info_agg     AS mi_agg   ON mi_agg.info_type_id = it.id
LEFT JOIN movie_info_idx_agg AS mi_idx_agg ON mi_idx_agg.info_type_id = it.id
LEFT JOIN person_info_agg    AS pi_agg   ON pi_agg.info_type_id = it.id
ORDER BY distinct_movie_cnt DESC, distinct_person_cnt DESC
