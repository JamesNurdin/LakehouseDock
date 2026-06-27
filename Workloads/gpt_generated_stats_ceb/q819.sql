WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score,
           COALESCE(AVG(c.score), 0) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_count,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_given,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_given
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COUNT(t.id) AS tag_count,
           COALESCE(SUM(t.count), 0) AS tag_usage_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0)            AS post_count,
       COALESCE(up.total_post_score, 0)      AS total_post_score,
       COALESCE(uc.comment_count, 0)         AS comment_count,
       COALESCE(uc.total_comment_score, 0)   AS total_comment_score,
       COALESCE(ub.badge_count, 0)           AS badge_count,
       COALESCE(uv.vote_count, 0)            AS vote_count,
       COALESCE(uv.upvotes_given, 0)         AS upvotes_given,
       COALESCE(uv.downvotes_given, 0)       AS downvotes_given,
       COALESCE(ue.edit_count, 0)            AS edit_count,
       COALESCE(ut.tag_count, 0)             AS tag_count,
       COALESCE(ut.tag_usage_sum, 0)         AS tag_usage_sum
FROM users u
LEFT JOIN user_posts    up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges   ub ON ub.user_id = u.id
LEFT JOIN user_votes    uv ON uv.user_id = u.id
LEFT JOIN user_edits    ue ON ue.user_id = u.id
LEFT JOIN user_tags     ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
