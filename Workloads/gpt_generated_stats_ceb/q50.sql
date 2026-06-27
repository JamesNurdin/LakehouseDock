WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views,
           COALESCE(SUM(p.answercount), 0) AS total_answers,
           COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_cast_count,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_cast
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
),
user_links AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT pl.id) AS link_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON (pl.postid = p.id OR pl.relatedpostid = p.id)
    GROUP BY u.id
),
user_history AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS history_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.post_count,
       up.total_post_score,
       up.total_views,
       up.total_answers,
       up.total_comments_on_posts,
       uc.comment_count,
       uc.total_comment_score,
       uv.vote_cast_count,
       uv.upvote_cast,
       uv.downvote_cast,
       ub.badge_count,
       ut.tag_count,
       ul.link_count,
       uh.history_count
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes uv
    ON uv.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_tags ut
    ON ut.user_id = up.user_id
LEFT JOIN user_links ul
    ON ul.user_id = up.user_id
LEFT JOIN user_history uh
    ON uh.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
