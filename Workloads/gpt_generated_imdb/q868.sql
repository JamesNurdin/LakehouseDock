WITH company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_lengths AS (
    SELECT mi.movie_id,
           mi.info_type_id,
           AVG(LENGTH(mi.info)) AS avg_info_length
    FROM movie_info mi
    GROUP BY mi.movie_id, mi.info_type_id
),
info_idx_stats AS (
    SELECT mii.movie_id,
           mii.info_type_id,
           AVG(mii.note) AS avg_note
    FROM movie_info_idx mii
    GROUP BY mii.movie_id, mii.info_type_id
),
person_counts AS (
    SELECT pi.info_type_id,
           COUNT(DISTINCT pi.person_id) AS person_count
    FROM person_info pi
    GROUP BY pi.info_type_id
)
SELECT
    t.production_year,
    it.info,
    AVG(co.company_count) AS avg_company_count,
    AVG(kw.keyword_count) AS avg_keyword_count,
    AVG(il.avg_info_length) AS avg_info_length,
    AVG(ii.avg_note) AS avg_note_value,
    MAX(pc.person_count) AS person_count
FROM title t
LEFT JOIN company_counts co ON co.movie_id = t.id
LEFT JOIN keyword_counts kw ON kw.movie_id = t.id
LEFT JOIN info_lengths il ON il.movie_id = t.id
LEFT JOIN info_idx_stats ii ON ii.movie_id = t.id
LEFT JOIN info_type it ON it.id = COALESCE(il.info_type_id, ii.info_type_id)
LEFT JOIN person_counts pc ON pc.info_type_id = it.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, it.info
ORDER BY avg_company_count DESC
LIMIT 20
