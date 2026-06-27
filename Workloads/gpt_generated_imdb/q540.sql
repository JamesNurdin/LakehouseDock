WITH company_type_stats AS (
    SELECT
        ct.id AS ct_id,
        ct.kind,
        COUNT(DISTINCT mc.movie_id) AS movie_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        AVG(LENGTH(mc.note)) AS avg_note_len,
        SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS note_nonnull_cnt
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY ct.id, ct.kind
)
SELECT
    kind,
    movie_cnt,
    company_cnt,
    avg_note_len,
    note_nonnull_cnt,
    RANK() OVER (ORDER BY movie_cnt DESC) AS movie_cnt_rank
FROM company_type_stats
ORDER BY movie_cnt DESC
LIMIT 10
