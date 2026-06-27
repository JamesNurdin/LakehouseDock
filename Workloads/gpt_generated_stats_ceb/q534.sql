WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.viewcount) AS post_viewcount_avg
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_cast_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_received_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT
            u.id AS user_id,
            COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    user_post_edits AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS posts_edited_count
        FROM users u
        LEFT JOIN posts p ON p.lasteditoruserid = u.id
        GROUP BY u.id
    ),
    user_posthistory_actions AS (
        SELECT
            u.id AS user_id,
            COUNT(ph.id) AS posthistory_actions_count
        FROM users u
        LEFT JOIN posthistory ph ON ph.userid = u.id
        GROUP BY u.id
    ),
    user_posthistory_on_owned_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(ph.id) AS posthistory_on_owned_posts_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
        GROUP BY u.id
    )
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_viewcount_avg, 0) AS post_viewcount_avg,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(uvc.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.posts_edited_count, 0) AS posts_edited_count,
    COALESCE(upa.posthistory_actions_count, 0) AS posthistory_actions_count,
    COALESCE(uop.posthistory_on_owned_posts_count, 0) AS posthistory_on_owned_posts_count,
    (
        COALESCE(up.post_count, 0) +
        COALESCE(uc.comment_count, 0) +
        COALESCE(uvc.votes_cast_count, 0) +
        COALESCE(uvr.votes_received_count, 0) +
        COALESCE(ub.badge_count, 0) +
        COALESCE(ue.posts_edited_count, 0) +
        COALESCE(upa.posthistory_actions_count, 0) +
        COALESCE(uop.posthistory_on_owned_posts_count, 0)
    ) AS activity_score,
    RANK() OVER (
        ORDER BY (
            COALESCE(up.post_count, 0) +
            COALESCE(uc.comment_count, 0) +
            COALESCE(uvc.votes_cast_count, 0) +
            COALESCE(uvr.votes_received_count, 0) +
            COALESCE(ub.badge_count, 0) +
            COALESCE(ue.posts_edited_count, 0) +
            COALESCE(upa.posthistory_actions_count, 0) +
            COALESCE(uop.posthistory_on_owned_posts_count, 0)
        ) DESC
    ) AS activity_rank
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_post_edits ue ON ue.user_id = u.id
LEFT JOIN user_posthistory_actions upa ON upa.user_id = u.id
LEFT JOIN user_posthistory_on_owned_posts uop ON uop.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
