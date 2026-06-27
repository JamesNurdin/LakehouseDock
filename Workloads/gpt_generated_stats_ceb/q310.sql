WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
post_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(v.id) AS votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT v.userid AS user_id,
           COUNT(v.id) AS votes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT b.userid AS user_id,
           COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_score, 0) AS total_post_score,
       CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
            ELSE COALESCE(up.total_score, 0) / NULLIF(COALESCE(up.post_count, 0), 0)
       END AS avg_score_per_post,
       COALESCE(pv.votes_received, 0) AS votes_received,
       COALESCE(pv.upvotes_received, 0) AS upvotes_received,
       COALESCE(pv.downvotes_received, 0) AS downvotes_received,
       COALESCE(vc.votes_cast, 0) AS votes_cast,
       COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(ub.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN post_votes_received pv
    ON pv.user_id = u.id
LEFT JOIN user_votes_cast vc
    ON vc.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
ORDER BY u.reputation DESC, badge_count DESC
LIMIT 10
