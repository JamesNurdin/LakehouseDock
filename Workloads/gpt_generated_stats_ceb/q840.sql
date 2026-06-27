WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS post_score_sum,
           COALESCE(SUM(p.viewcount), 0) AS post_view_sum,
           COALESCE(SUM(p.answercount), 0) AS post_answer_sum
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments_on_posts AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_on_owned_posts,
           COALESCE(AVG(c.score), 0) AS avg_comment_score_on_owned_posts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
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
),
user_outgoing_links AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS outgoing_links
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_incoming_links AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS incoming_links
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.relatedpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.post_count,
       up.post_score_sum,
       uc.comment_on_owned_posts,
       uc.avg_comment_score_on_owned_posts,
       vr.votes_received,
       vr.upvotes_received,
       vr.downvotes_received,
       vc.votes_cast,
       vc.upvotes_cast,
       vc.downvotes_cast,
       ub.badge_count,
       ph.posthistory_count,
       tg.distinct_tag_count,
       ol.outgoing_links,
       il.incoming_links
FROM users u
LEFT JOIN user_posts up            ON up.user_id = u.id
LEFT JOIN user_comments_on_posts uc ON uc.user_id = u.id
LEFT JOIN user_votes_received vr   ON vr.user_id = u.id
LEFT JOIN user_votes_cast vc       ON vc.user_id = u.id
LEFT JOIN user_badges ub           ON ub.user_id = u.id
LEFT JOIN user_posthistory ph      ON ph.user_id = u.id
LEFT JOIN user_tags tg             ON tg.user_id = u.id
LEFT JOIN user_outgoing_links ol   ON ol.user_id = u.id
LEFT JOIN user_incoming_links il   ON il.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
