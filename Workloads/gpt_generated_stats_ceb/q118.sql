WITH post_comment_agg AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_cnt,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM comments c
    GROUP BY c.postid
),

tag_post_map AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
)
SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id) AS post_cnt,
    SUM(p.score) AS total_post_score,
    AVG(p.score) AS avg_post_score,
    COALESCE(SUM(pc.comment_cnt), 0) AS total_comment_cnt,
    COALESCE(AVG(pc.comment_score_avg), 0) AS avg_comment_score_per_post,
    COUNT(DISTINCT p.owneruserid) AS distinct_owner_user_cnt,
    COUNT(DISTINCT p.lasteditoruserid) AS distinct_editor_user_cnt,
    SUM(u_owner.reputation) AS total_owner_reputation,
    SUM(u_editor.reputation) AS total_editor_reputation
FROM tag_post_map tp
JOIN posts p
    ON tp.post_id = p.id
LEFT JOIN post_comment_agg pc
    ON p.id = pc.post_id
JOIN users u_owner
    ON p.owneruserid = u_owner.id
JOIN users u_editor
    ON p.lasteditoruserid = u_editor.id
GROUP BY tp.tag_id
ORDER BY total_post_score DESC
LIMIT 20
