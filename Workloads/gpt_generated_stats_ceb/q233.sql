WITH comment_stats AS (
    SELECT
        c.postid AS post_id,
        COUNT(c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        COUNT(DISTINCT c.userid) AS distinct_commenters,
        AVG(u.reputation) AS avg_commenter_reputation
    FROM comments c
    JOIN users u ON u.id = c.userid
    GROUP BY c.postid
),
post_details AS (
    SELECT
        p.id AS post_id,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid,
        p.answercount,
        p.favoritecount
    FROM posts p
)
SELECT
    pd.post_id,
    pd.creationdate,
    pd.score AS post_score,
    pd.viewcount,
    pd.answercount,
    pd.favoritecount,
    u_owner.reputation AS owner_reputation,
    u_editor.reputation AS editor_reputation,
    cs.comment_count,
    cs.avg_comment_score,
    cs.distinct_commenters,
    cs.avg_commenter_reputation,
    (cs.comment_count * 1.0 / NULLIF(pd.viewcount, 0)) AS comment_to_view_ratio
FROM post_details pd
LEFT JOIN comment_stats cs ON cs.post_id = pd.post_id
LEFT JOIN users u_owner ON u_owner.id = pd.owneruserid
LEFT JOIN users u_editor ON u_editor.id = pd.lasteditoruserid
ORDER BY pd.score DESC
LIMIT 20
