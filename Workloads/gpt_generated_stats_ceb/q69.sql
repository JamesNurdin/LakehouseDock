WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           SUM(p.score) AS total_score,
           AVG(p.score) AS avg_score,
           SUM(p.viewcount) AS total_views,
           COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS answer_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_edits_made AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edits_made
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_edits_received AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edits_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_score, 0) AS total_score,
       COALESCE(up.avg_score, 0) AS avg_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(up.answer_count, 0) AS answer_count,
       COALESCE(vc.votes_cast, 0) AS votes_cast,
       COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(vr.votes_received, 0) AS votes_received,
       COALESCE(vr.upvotes_received, 0) AS upvotes_received,
       COALESCE(vr.downvotes_received, 0) AS downvotes_received,
       COALESCE(em.edits_made, 0) AS edits_made,
       COALESCE(er.edits_received, 0) AS edits_received
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_edits_made em ON em.user_id = u.id
LEFT JOIN user_edits_received er ON er.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
