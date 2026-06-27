WITH user_posts AS (
    SELECT u.id AS userid,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorites,
           COALESCE(SUM(p.answercount), 0) AS total_answers,
           COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS userid,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS userid,
           COUNT(v.id) AS votes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT u.id AS userid,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS userid,
           COUNT(p.id) AS edited_posts
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(up.total_favorites, 0) AS total_favorites,
       COALESCE(up.total_answers, 0) AS total_answers,
       COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
       COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edited_posts, 0) AS edited_posts
FROM users u
LEFT JOIN user_posts up
    ON up.userid = u.id
LEFT JOIN user_comments uc
    ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc
    ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr
    ON uvr.userid = u.id
LEFT JOIN user_badges ub
    ON ub.userid = u.id
LEFT JOIN user_edits ue
    ON ue.userid = u.id
ORDER BY total_post_score DESC
LIMIT 100
