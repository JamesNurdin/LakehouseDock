WITH link_stats AS (
    SELECT
        pl.linktypeid,
        COUNT(*) AS link_count,
        AVG(p_source.score) AS avg_source_score,
        AVG(p_target.score) AS avg_target_score,
        SUM(p_source.viewcount) AS sum_source_viewcount,
        SUM(p_target.viewcount) AS sum_target_viewcount,
        COUNT(DISTINCT p_source.owneruserid) AS distinct_source_owners,
        COUNT(DISTINCT p_target.owneruserid) AS distinct_target_owners
    FROM postlinks pl
    JOIN posts p_source
      ON pl.postid = p_source.id
    JOIN posts p_target
      ON pl.relatedpostid = p_target.id
    GROUP BY pl.linktypeid
)
SELECT
    linktypeid,
    link_count,
    avg_source_score,
    avg_target_score,
    sum_source_viewcount,
    sum_target_viewcount,
    distinct_source_owners,
    distinct_target_owners,
    (sum_source_viewcount * 1.0 / NULLIF(sum_target_viewcount, 0)) AS source_to_target_view_ratio,
    RANK() OVER (ORDER BY link_count DESC) AS link_type_rank
FROM link_stats
ORDER BY link_count DESC
LIMIT 10
