WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_post_views,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_given AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_given,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_given,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(ug.votes_given, 0) AS votes_given,
       COALESCE(ur.votes_received, 0) AS votes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN user_posts up      ON up.user_id = u.id
LEFT JOIN user_comments uc   ON uc.user_id = u.id
LEFT JOIN user_votes_given ug ON ug.user_id = u.id
LEFT JOIN user_votes_received ur ON ur.user_id = u.id
LEFT JOIN user_badges ub    ON ub.user_id = u.id
LEFT JOIN user_edits ue      ON ue.user_id = u.id
ORDER BY (
        COALESCE(up.total_post_score, 0) +
        COALESCE(uc.total_comment_score, 0) +
        COALESCE(ur.upvotes_received, 0) -
        COALESCE(ur.downvotes_received, 0)
       ) DESC
LIMIT 10
