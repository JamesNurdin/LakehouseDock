WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.answercount), 0) AS total_answers,
           COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
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
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(vr.id) AS votes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes vr ON vr.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tagged_posts AS (
    SELECT u.id AS user_id,
           COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.post_count,
       up.total_post_score,
       up.total_answers,
       up.total_comments_on_posts,
       uc.comment_count,
       ub.badge_count,
       uvc.votes_cast,
       uvc.total_bounty_cast,
       uvr.votes_received,
       uph.posthistory_count,
       utp.tag_count,
       upl.postlink_count,
       (COALESCE(up.post_count, 0) * 5
        + COALESCE(uc.comment_count, 0) * 2
        + COALESCE(ub.badge_count, 0) * 3
        + COALESCE(uvc.votes_cast, 0) * 1
        + COALESCE(uvr.votes_received, 0) * 1
        + COALESCE(up.total_post_score, 0) * 0.1
        + COALESCE(upl.postlink_count, 0) * 0.5) AS activity_score
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = up.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
LEFT JOIN user_tagged_posts utp ON utp.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY activity_score DESC
LIMIT 20
