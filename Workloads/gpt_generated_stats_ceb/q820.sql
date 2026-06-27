WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            COALESCE(SUM(p.score), 0) AS post_score_sum,
            COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum
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
            COALESCE(SUM(v.bountyamount), 0) AS bounty_amount_sum
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_received_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY u.id
    ),
    user_tags_excerpts AS (
        SELECT
            u.id AS user_id,
            COUNT(t.id) AS tag_excerpt_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN tags t ON t.excerptpostid = p.id
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
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.bounty_amount_sum, 0) AS bounty_amount_sum,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vr.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    (
        5 * COALESCE(up.post_count, 0) +
        2 * COALESCE(uc.comment_count, 0) +
        1 * COALESCE(uvc.votes_cast_count, 0) +
        3 * COALESCE(vr.votes_received_count, 0) +
        1 * COALESCE(ute.tag_excerpt_count, 0) +
        1 * COALESCE(uph.posthistory_count, 0)
    ) AS activity_score
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN user_tags_excerpts ute ON ute.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
ORDER BY activity_score DESC
LIMIT 10
