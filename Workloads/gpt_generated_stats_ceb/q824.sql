WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS post_viewcount_sum,
        SUM(p.answercount) AS post_answercount_sum,
        SUM(p.favoritecount) AS post_favoritecount_sum
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS bounty_amount_cast_sum
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS bounty_amount_received_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(up.post_answercount_sum, 0) AS post_answercount_sum,
    COALESCE(up.post_favoritecount_sum, 0) AS post_favoritecount_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.bounty_amount_cast_sum, 0) AS bounty_amount_cast_sum,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.bounty_amount_received_sum, 0) AS bounty_amount_received_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    RANK() OVER (
        ORDER BY (
            COALESCE(up.post_count, 0) +
            COALESCE(uc.comment_count, 0) +
            COALESCE(uvc.votes_cast_count, 0) +
            COALESCE(uvr.votes_received_count, 0) +
            COALESCE(ub.badge_count, 0)
        ) DESC
    ) AS activity_rank
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
