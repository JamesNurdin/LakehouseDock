WITH link_stats AS (
    SELECT
        pl.linktypeid,
        date_trunc('month', pl.creationdate) AS link_month,
        COUNT(*) AS link_count,
        AVG(p_src.score) AS avg_source_score,
        AVG(p_tgt.score) AS avg_target_score,
        SUM(p_src.viewcount) AS sum_source_viewcount,
        SUM(p_tgt.viewcount) AS sum_target_viewcount,
        COUNT(DISTINCT p_src.owneruserid) AS distinct_source_owners,
        COUNT(DISTINCT p_tgt.owneruserid) AS distinct_target_owners
    FROM postlinks pl
    JOIN posts p_src ON pl.postid = p_src.id
    JOIN posts p_tgt ON pl.relatedpostid = p_tgt.id
    GROUP BY pl.linktypeid, date_trunc('month', pl.creationdate)
)
SELECT
    linktypeid,
    link_month,
    link_count,
    avg_source_score,
    avg_target_score,
    sum_source_viewcount,
    sum_target_viewcount,
    distinct_source_owners,
    distinct_target_owners
FROM link_stats
ORDER BY link_month DESC, linktypeid
