WITH user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_views,
           SUM(answercount) AS total_answers,
           SUM(commentcount) AS total_comments_on_posts,
           SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score
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
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks_outbound AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS outbound_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_inbound AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS inbound_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
       COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(uplo.outbound_links, 0) AS outbound_links,
       COALESCE(upli.inbound_links, 0) AS inbound_links
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_postlinks_outbound uplo ON uplo.userid = u.id
LEFT JOIN user_postlinks_inbound upli ON upli.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
