WITH user_posts AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS post_count,
               AVG(p.score) AS avg_post_score,
               SUM(p.viewcount) AS total_views
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT u.id AS user_id,
               COUNT(c.id) AS comment_count
        FROM users u
        LEFT JOIN comments c
               ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes AS (
        SELECT u.id AS user_id,
               COUNT(v.id) AS vote_cast_count,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
               SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
        FROM users u
        LEFT JOIN votes v
               ON v.userid = u.id
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
    user_tags AS (
        SELECT u.id AS user_id,
               COUNT(DISTINCT t.id) AS tag_count
        FROM users u
        LEFT JOIN posts p
               ON p.owneruserid = u.id
        LEFT JOIN tags t
               ON t.excerptpostid = p.id
        GROUP BY u.id
    )
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0)          AS post_count,
       COALESCE(up.avg_post_score, 0)      AS avg_post_score,
       COALESCE(up.total_views, 0)         AS total_views,
       COALESCE(uc.comment_count, 0)       AS comment_count,
       COALESCE(uv.vote_cast_count, 0)     AS vote_cast_count,
       COALESCE(uv.upvote_cast_count, 0)   AS upvote_cast_count,
       COALESCE(uv.downvote_cast_count, 0) AS downvote_cast_count,
       COALESCE(ub.badge_count, 0)         AS badge_count,
       COALESCE(ut.tag_count, 0)           AS tag_count
FROM users u
LEFT JOIN user_posts    up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes    uv ON uv.user_id = u.id
LEFT JOIN user_badges   ub ON ub.user_id = u.id
LEFT JOIN user_tags     ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
