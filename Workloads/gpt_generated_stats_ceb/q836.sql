WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS total_posts,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.score), 0) AS avg_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
           COALESCE(AVG(p.viewcount), 0) AS avg_viewcount
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments_made AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS total_comments_made
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_comments_received AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS total_comments_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS total_posthistory_entries
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_tags_in_posts AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tags_in_user_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.total_posts,
       up.total_post_score,
       up.avg_post_score,
       up.total_viewcount,
       up.avg_viewcount,
       ucm.total_comments_made,
       ucr.total_comments_received,
       uv_cast.total_votes_cast,
       uv_received.total_votes_received,
       ub.total_badges,
       uph.total_posthistory_entries,
       ut.distinct_tags_in_user_posts,
       CASE WHEN uv_cast.total_votes_cast > 0
            THEN uv_received.total_votes_received * 1.0 / uv_cast.total_votes_cast
            ELSE NULL END AS vote_received_per_cast,
       CASE WHEN up.total_posts > 0
            THEN ucr.total_comments_received * 1.0 / up.total_posts
            ELSE NULL END AS avg_comments_per_post
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_comments_made ucm
    ON ucm.user_id = u.id
LEFT JOIN user_comments_received ucr
    ON ucr.user_id = u.id
LEFT JOIN user_votes_cast uv_cast
    ON uv_cast.user_id = u.id
LEFT JOIN user_votes_received uv_received
    ON uv_received.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
LEFT JOIN user_posthistory uph
    ON uph.user_id = u.id
LEFT JOIN user_tags_in_posts ut
    ON ut.user_id = u.id
ORDER BY up.total_posts DESC
LIMIT 100
