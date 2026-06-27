WITH user_post_stats AS (
    SELECT
        owner.id AS user_id,
        owner.reputation AS user_reputation,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        COUNT(DISTINCT ph.id) AS posthistory_actions,
        AVG(editor.reputation) AS avg_editor_reputation
    FROM users owner
    JOIN posts p ON p.owneruserid = owner.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    LEFT JOIN users editor ON p.lasteditoruserid = editor.id
    GROUP BY owner.id, owner.reputation
)
SELECT
    user_id,
    user_reputation,
    post_count,
    total_score,
    avg_score,
    total_views,
    posthistory_actions,
    avg_editor_reputation
FROM user_post_stats
ORDER BY total_score DESC
LIMIT 20
