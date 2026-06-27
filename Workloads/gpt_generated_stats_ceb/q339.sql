WITH comment_stats AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score,
        COUNT(DISTINCT c.userid) AS distinct_commenters
    FROM comments c
    GROUP BY c.postid
),
posthistory_stats AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS posthistory_count,
        COUNT(DISTINCT ph.userid) AS distinct_editors
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    p.id AS post_id,
    p.creationdate AS post_creationdate,
    p.score AS post_score,
    p.viewcount AS post_viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    o.id AS owner_user_id,
    o.reputation AS owner_reputation,
    le.id AS last_editor_user_id,
    le.reputation AS last_editor_reputation,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(cs.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(cs.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(phs.posthistory_count, 0) AS posthistory_count,
    COALESCE(phs.distinct_editors, 0) AS distinct_editors
FROM posts p
LEFT JOIN comment_stats cs
    ON cs.post_id = p.id
LEFT JOIN posthistory_stats phs
    ON phs.post_id = p.id
LEFT JOIN users o
    ON o.id = p.owneruserid
LEFT JOIN users le
    ON le.id = p.lasteditoruserid
ORDER BY total_comment_score DESC
LIMIT 10
