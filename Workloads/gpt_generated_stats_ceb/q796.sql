WITH user_posts_agg AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           AVG(p.score) AS avg_post_score,
           SUM(p.viewcount) AS total_views
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments_agg AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           SUM(c.score) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast_agg AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast_count
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received_agg AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges_agg AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_tags_agg AS (
    SELECT u.id AS user_id,
           COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_posthistory_agg AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_postlinks_agg AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS postlinks_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(pagg.post_count, 0) AS post_count,
       COALESCE(pagg.avg_post_score, 0.0) AS avg_post_score,
       COALESCE(pagg.total_views, 0) AS total_post_views,
       COALESCE(cagg.comment_count, 0) AS comment_count,
       COALESCE(cagg.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(vcast.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(vrecv.votes_received_count, 0) AS votes_received_count,
       COALESCE(vrecv.upvotes_received, 0) AS upvotes_received,
       COALESCE(vrecv.downvotes_received, 0) AS downvotes_received,
       COALESCE(bagg.badge_count, 0) AS badge_count,
       COALESCE(tagagg.tag_count, 0) AS tag_count,
       COALESCE(phagg.posthistory_count, 0) AS posthistory_count,
       COALESCE(plagg.postlinks_count, 0) AS postlinks_count,
       (COALESCE(pagg.post_count, 0) + COALESCE(cagg.comment_count, 0) + COALESCE(vcast.votes_cast_count, 0) + COALESCE(bagg.badge_count, 0) + COALESCE(tagagg.tag_count, 0) + COALESCE(phagg.posthistory_count, 0) + COALESCE(plagg.postlinks_count, 0)) AS total_activity_score
FROM users u
LEFT JOIN user_posts_agg pagg ON pagg.user_id = u.id
LEFT JOIN user_comments_agg cagg ON cagg.user_id = u.id
LEFT JOIN user_votes_cast_agg vcast ON vcast.user_id = u.id
LEFT JOIN user_votes_received_agg vrecv ON vrecv.user_id = u.id
LEFT JOIN user_badges_agg bagg ON bagg.user_id = u.id
LEFT JOIN user_tags_agg tagagg ON tagagg.user_id = u.id
LEFT JOIN user_posthistory_agg phagg ON phagg.user_id = u.id
LEFT JOIN user_postlinks_agg plagg ON plagg.user_id = u.id
ORDER BY total_activity_score DESC
LIMIT 10
