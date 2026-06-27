WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views,
           COALESCE(SUM(p.answercount), 0) AS total_answers,
           COALESCE(SUM(p.commentcount), 0) AS total_comments,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
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
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v2.id) AS votes_received,
           COALESCE(SUM(CASE WHEN v2.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
           COALESCE(SUM(CASE WHEN v2.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v2 ON v2.postid = p.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(AVG(c.score), 0) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0)               AS post_count,
       COALESCE(up.total_post_score, 0)         AS total_post_score,
       COALESCE(up.total_views, 0)              AS total_views,
       COALESCE(up.total_answers, 0)            AS total_answers,
       COALESCE(up.total_comments, 0)           AS total_comments,
       COALESCE(up.total_favorites, 0)          AS total_favorites,
       COALESCE(ub.badge_count, 0)              AS badge_count,
       COALESCE(uvc.votes_cast, 0)              AS votes_cast,
       COALESCE(uvc.upvotes_cast, 0)            AS upvotes_cast,
       COALESCE(uvc.downvotes_cast, 0)          AS downvotes_cast,
       COALESCE(uvr.votes_received, 0)          AS votes_received,
       COALESCE(uvr.upvotes_received, 0)        AS upvotes_received,
       COALESCE(uvr.downvotes_received, 0)      AS downvotes_received,
       COALESCE(uc.comment_count, 0)            AS comment_count,
       COALESCE(uc.avg_comment_score, 0)        AS avg_comment_score,
       COALESCE(uph.posthistory_count, 0)      AS posthistory_count,
       COALESCE(ut.distinct_tag_count, 0)       AS distinct_tag_count
FROM users u
LEFT JOIN user_posts up            ON up.user_id = u.id
LEFT JOIN user_badges ub           ON ub.user_id = u.id
LEFT JOIN user_votes_cast uvc      ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr  ON uvr.user_id = u.id
LEFT JOIN user_comments uc         ON uc.user_id = u.id
LEFT JOIN user_posthistory uph     ON uph.user_id = u.id
LEFT JOIN user_tags ut             ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
