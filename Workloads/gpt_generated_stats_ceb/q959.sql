WITH tag_post_metrics AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.viewcount,
        p.score,
        u_owner.reputation AS owner_rep,
        u_editor.reputation AS editor_rep
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    JOIN users u_owner
        ON p.owneruserid = u_owner.id
    LEFT JOIN users u_editor
        ON p.lasteditoruserid = u_editor.id
)
SELECT
    tag_id,
    COUNT(post_id) AS post_count,
    SUM(viewcount) AS total_viewcount,
    AVG(score) AS avg_score,
    AVG(owner_rep) AS avg_owner_reputation,
    AVG(editor_rep) AS avg_editor_reputation
FROM tag_post_metrics
GROUP BY tag_id
ORDER BY total_viewcount DESC
LIMIT 10
