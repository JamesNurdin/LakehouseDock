WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS total_posts,
           COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS total_answers,
           AVG(p.score) AS avg_post_score,
           SUM(p.viewcount) AS total_viewcount,
           SUM(p.favoritecount) AS total_favoritecount,
           SUM(p.commentcount) AS total_commentcount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS total_comments_made
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_cast,
           COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_cast,
           COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_received,
           COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_received,
           COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS total_post_links
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_tag_counts AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS total_posthistory_events
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_posthistory_by_type AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS total_posthistory_by_type
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.total_posts,
       up.total_answers,
       up.avg_post_score,
       up.total_viewcount,
       up.total_favoritecount,
       up.total_commentcount,
       uc.total_comments_made,
       uv_cast.total_votes_cast,
       uv_cast.upvotes_cast,
       uv_cast.downvotes_cast,
       uv_received.total_votes_received,
       uv_received.upvotes_received,
       uv_received.downvotes_received,
       ub.total_badges,
       upl.total_post_links,
       ut.distinct_tag_count,
       uph.total_posthistory_events,
       upht.total_posthistory_by_type
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_received ON uv_received.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
LEFT JOIN user_tag_counts ut ON ut.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
LEFT JOIN user_posthistory_by_type upht ON upht.user_id = up.user_id
ORDER BY up.total_posts DESC
LIMIT 100
