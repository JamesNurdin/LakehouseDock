WITH user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(viewcount) AS avg_post_viewcount,
           MAX(creationdate) AS last_post_date
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid,
           COUNT(*) AS votes_cast,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS votes_received,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
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
user_edits AS (
    SELECT userid,
           COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_owned_posthistory AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS owned_posthistory_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_related_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS related_link_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate AS user_creation_date,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_post_viewcount, 0) AS avg_post_viewcount,
       COALESCE(up.last_post_date, TIMESTAMP '1970-01-01 00:00:00 UTC') AS last_post_date,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
       COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(uoph.owned_posthistory_count, 0) AS owned_posthistory_count,
       COALESCE(ul.link_count, 0) AS link_count,
       COALESCE(urll.related_link_count, 0) AS related_link_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
LEFT JOIN user_owned_posthistory uoph ON u.id = uoph.userid
LEFT JOIN user_links ul ON u.id = ul.userid
LEFT JOIN user_related_links urll ON u.id = urll.userid
ORDER BY u.reputation DESC
LIMIT 100
