WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_count
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_last_edits AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS last_edit_count
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.post_count,
       up.total_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(ule.last_edit_count, 0) AS last_edit_count,
       (up.post_count * 5
        + COALESCE(uc.comment_count, 0) * 2
        + COALESCE(uv.vote_count, 0) * 1
        + COALESCE(ub.badge_count, 0) * 3
        + up.total_post_score
        + COALESCE(ue.edit_count, 0) * 2
        + COALESCE(ule.last_edit_count, 0) * 2) AS activity_score
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes uv ON uv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_last_edits ule ON ule.user_id = up.user_id
ORDER BY activity_score DESC
LIMIT 10
