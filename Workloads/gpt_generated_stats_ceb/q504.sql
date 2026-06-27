WITH post_stats AS (
    SELECT
        p.id AS post_id,
        p.creationdate AS post_creationdate,
        p.owneruserid AS owner_user_id,
        p.lasteditoruserid AS last_editor_user_id,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(COALESCE(c.score, 0)) AS comment_score_sum,
        COUNT(DISTINCT v.id) AS vote_count,
        COUNT(DISTINCT ph.id) AS edit_count
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    LEFT JOIN votes v
        ON v.postid = p.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY p.id, p.creationdate, p.owneruserid, p.lasteditoruserid
)
SELECT
    ps.post_id,
    ps.post_creationdate,
    u_owner.reputation AS owner_reputation,
    u_editor.reputation AS editor_reputation,
    ps.comment_count,
    ps.comment_score_sum,
    ps.vote_count,
    ps.edit_count
FROM post_stats ps
LEFT JOIN users u_owner
    ON u_owner.id = ps.owner_user_id
LEFT JOIN users u_editor
    ON u_editor.id = ps.last_editor_user_id
ORDER BY ps.comment_count DESC
LIMIT 100
