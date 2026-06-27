WITH user_metrics AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(DISTINCT b.id) AS badge_count,
        COUNT(DISTINCT p_owner.id) AS owned_post_count,
        SUM(p_owner.score) AS owned_post_score_sum,
        AVG(p_owner.score) AS owned_post_score_avg,
        COUNT(DISTINCT p_editor.id) AS edited_post_count,
        SUM(p_editor.score) AS edited_post_score_sum,
        AVG(p_editor.score) AS edited_post_score_avg,
        COUNT(DISTINCT ph.id) AS posthistory_entry_count,
        COUNT(DISTINCT ph_post.id) AS posthistory_related_post_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    LEFT JOIN posts p_owner
        ON p_owner.owneruserid = u.id
    LEFT JOIN posts p_editor
        ON p_editor.lasteditoruserid = u.id
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts ph_post
        ON ph.posthistorytypeid = ph_post.id
    GROUP BY u.id, u.reputation
)
SELECT
    user_id,
    reputation,
    badge_count,
    owned_post_count,
    owned_post_score_sum,
    owned_post_score_avg,
    edited_post_count,
    edited_post_score_sum,
    edited_post_score_avg,
    posthistory_entry_count,
    posthistory_related_post_count
FROM user_metrics
ORDER BY reputation DESC
LIMIT 10
