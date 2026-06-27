WITH out_link_stats AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS out_link_count,
        AVG(p2.score) AS out_link_avg_score
    FROM postlinks pl
    JOIN posts p2 ON pl.relatedpostid = p2.id
    GROUP BY pl.postid
),
in_link_stats AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS in_link_count,
        AVG(p1.score) AS in_link_avg_score
    FROM postlinks pl
    JOIN posts p1 ON pl.postid = p1.id
    GROUP BY pl.relatedpostid
),
history_stats AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS history_count,
        COUNT(DISTINCT ph.userid) AS distinct_user_history_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    p.id,
    p.posttypeid,
    p.creationdate,
    p.score,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(ols.out_link_count, 0) AS out_link_count,
    COALESCE(ols.out_link_avg_score, 0) AS out_link_avg_score,
    COALESCE(ils.in_link_count, 0) AS in_link_count,
    COALESCE(ils.in_link_avg_score, 0) AS in_link_avg_score,
    COALESCE(hs.history_count, 0) AS history_count,
    COALESCE(hs.distinct_user_history_count, 0) AS distinct_user_history_count
FROM posts p
LEFT JOIN out_link_stats ols ON ols.post_id = p.id
LEFT JOIN in_link_stats ils ON ils.post_id = p.id
LEFT JOIN history_stats hs ON hs.post_id = p.id
ORDER BY p.creationdate DESC
LIMIT 100
