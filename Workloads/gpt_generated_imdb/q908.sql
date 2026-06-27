WITH note_stats AS (
    SELECT
        mc.id AS movie_company_id,
        mc.movie_id,
        mc.company_id,
        mc.company_type_id,
        length(mc.note) AS note_len
    FROM movie_companies mc
    WHERE mc.note IS NOT NULL
),
aggregated AS (
    SELECT
        ct.kind,
        COUNT(DISTINCT ns.movie_id) AS distinct_movie_count,
        COUNT(DISTINCT ns.company_id) AS distinct_company_count,
        AVG(ns.note_len) AS avg_note_length,
        SUM(CASE WHEN ns.note_len > 100 THEN 1 ELSE 0 END) AS long_note_count
    FROM note_stats ns
    JOIN company_type ct ON ns.company_type_id = ct.id
    GROUP BY ct.kind
)
SELECT
    kind,
    distinct_movie_count,
    distinct_company_count,
    avg_note_length,
    long_note_count,
    RANK() OVER (ORDER BY distinct_movie_count DESC) AS movie_count_rank
FROM aggregated
ORDER BY distinct_movie_count DESC
