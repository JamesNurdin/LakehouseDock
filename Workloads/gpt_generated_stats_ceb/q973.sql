WITH user_posts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(p.score) AS post_score_sum,
           SUM(p.viewcount) AS view_count_sum,
           SUM(p.answercount) AS answer_count_sum,
           SUM(p.favoritecount) AS favorite_count_sum
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments_made AS (
    SELECT c.userid AS user_id,
           COUNT(*) AS comments_made
    FROM comments c
    GROUP BY c.userid
),
user_comments_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS comments_received
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT v.userid AS user_id,
           COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT b.userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_postlinks AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT ph.userid AS user_id,
           COUNT(*) AS posthistory_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.post_score_sum, 0) AS post_score_sum,
       COALESCE(up.view_count_sum, 0) AS view_count_sum,
       COALESCE(up.answer_count_sum, 0) AS answer_count_sum,
       COALESCE(up.favorite_count_sum, 0) AS favorite_count_sum,
       COALESCE(cm.comments_made, 0) AS comments_made,
       COALESCE(cr.comments_received, 0) AS comments_received,
       COALESCE(vc.votes_cast, 0) AS votes_cast,
       COALESCE(vr.votes_received, 0) AS votes_received,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(pl.postlink_count, 0) AS postlink_count,
       COALESCE(ph.posthistory_count, 0) AS posthistory_count,
       COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts up          ON u.id = up.user_id
LEFT JOIN user_comments_made cm  ON u.id = cm.user_id
LEFT JOIN user_comments_received cr ON u.id = cr.user_id
LEFT JOIN user_votes_cast vc    ON u.id = vc.user_id
LEFT JOIN user_votes_received vr ON u.id = vr.user_id
LEFT JOIN user_badges b         ON u.id = b.user_id
LEFT JOIN user_postlinks pl     ON u.id = pl.user_id
LEFT JOIN user_posthistory ph   ON u.id = ph.user_id
LEFT JOIN user_tags t           ON u.id = t.user_id
ORDER BY u.reputation DESC
LIMIT 100
