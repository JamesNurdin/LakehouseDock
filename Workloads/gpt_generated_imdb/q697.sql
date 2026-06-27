WITH movie_counts AS (
    SELECT
        mc.company_type_id,
        COUNT(DISTINCT mc.movie_id) AS distinct_movie_cnt,
        COUNT(DISTINCT mc.company_id) AS distinct_company_cnt,
        COUNT(*) AS total_entries
    FROM movie_companies mc
    WHERE mc.note IS NOT NULL
    GROUP BY mc.company_type_id
    HAVING COUNT(*) > 5
)
SELECT
    ct.kind,
    mc.distinct_movie_cnt,
    mc.distinct_company_cnt,
    mc.total_entries,
    (mc.total_entries * 100.0) / SUM(mc.total_entries) OVER () AS pct_of_total_entries,
    RANK() OVER (ORDER BY mc.total_entries DESC) AS rank_by_entries
FROM movie_counts mc
JOIN company_type ct
    ON mc.company_type_id = ct.id
ORDER BY mc.total_entries DESC
