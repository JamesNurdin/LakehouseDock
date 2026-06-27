WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(SUM(p.viewcount), 0) AS post_view_sum
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_cast,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_cast_sum
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_received_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    JOIN users u ON p.owneruserid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.post_count,
    up.post_score_sum,
    uc.comment_count,
    uc.comment_score_sum,
    uvc.votes_cast_count,
    uvc.upvotes_cast,
    uvc.downvotes_cast,
    uvr.votes_received_count,
    uvr.upvotes_received,
    uvr.downvotes_received,
    uph.posthistory_count,
    (
        up.post_score_sum
        + uc.comment_score_sum
        + uvr.upvotes_received
        + uvc.upvotes_cast
        + uvr.bounty_received_sum
        + uvc.bounty_cast_sum
    ) AS activity_score
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = up.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
ORDER BY activity_score DESC
LIMIT 10
