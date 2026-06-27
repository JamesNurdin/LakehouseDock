WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS post_score_sum,
            COALESCE(SUM(viewcount), 0) AS post_view_sum
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS userid,
            COUNT(*) AS comment_count,
            COALESCE(SUM(score), 0) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS userid,
            COUNT(*) AS votes_cast_count,
            COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast_count,
            COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_received_count
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid AS userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    (COALESCE(up.post_count, 0) * 2
     + COALESCE(uc.comment_count, 0)
     + COALESCE(uvc.votes_cast_count, 0)
     + COALESCE(uvr.votes_received_count, 0)
     + COALESCE(ub.badge_count, 0) * 3) AS activity_score,
    RANK() OVER (
        ORDER BY (COALESCE(up.post_count, 0) * 2
                  + COALESCE(uc.comment_count, 0)
                  + COALESCE(uvc.votes_cast_count, 0)
                  + COALESCE(uvr.votes_received_count, 0)
                  + COALESCE(ub.badge_count, 0) * 3) DESC
    ) AS activity_rank
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
WHERE u.reputation > 0
ORDER BY activity_score DESC
LIMIT 100
