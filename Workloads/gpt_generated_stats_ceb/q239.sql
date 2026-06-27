WITH user_posts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(p.score) AS total_post_score,
           SUM(p.viewcount) AS total_views,
           SUM(p.answercount) AS total_answers,
           SUM(p.commentcount) AS total_comments_on_posts,
           SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT c.userid AS userid,
           COUNT(*) AS comment_count,
           SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT v.userid AS userid,
           COUNT(*) AS votes_cast,
           SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS votes_received,
           SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT b.userid AS userid,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT ph.userid AS userid,
           COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tag_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(up.total_answers, 0) AS total_answers,
       COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(up.total_favorites, 0) AS total_favorites,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.total_bounty_cast, 0) AS total_bounty_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_tag_counts ut ON ut.userid = u.id
ORDER BY u.reputation DESC
LIMIT 20
