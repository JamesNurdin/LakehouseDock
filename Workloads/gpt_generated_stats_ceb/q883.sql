WITH user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS post_score
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid,
           COUNT(*) AS votes_cast,
           SUM(COALESCE(bountyamount, 0)) AS bounty_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS votes_received,
           SUM(COALESCE(v.bountyamount, 0)) AS bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_tags AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0)      AS post_count,
       COALESCE(up.post_score, 0)      AS post_score,
       COALESCE(uc.comment_count, 0)   AS comment_count,
       COALESCE(uc.comment_score, 0)   AS comment_score,
       COALESCE(uvc.votes_cast, 0)     AS votes_cast,
       COALESCE(uvc.bounty_cast, 0)    AS bounty_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.bounty_received, 0) AS bounty_received,
       COALESCE(ub.badge_count, 0)     AS badge_count,
       COALESCE(ut.tag_count, 0)       AS tag_count,
       (COALESCE(up.post_score, 0) + COALESCE(uc.comment_score, 0) + COALESCE(uvr.votes_received, 0)) AS total_contribution
FROM users u
LEFT JOIN user_posts up          ON up.userid = u.id
LEFT JOIN user_comments uc       ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc    ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub         ON ub.userid = u.id
LEFT JOIN user_tags ut           ON ut.userid = u.id
ORDER BY total_contribution DESC
LIMIT 10
