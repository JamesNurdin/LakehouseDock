WITH badge_counts AS (
    SELECT b.userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
comment_counts AS (
    SELECT c.userid AS user_id,
           COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
vote_counts AS (
    SELECT v.userid AS user_id,
           COUNT(*) AS vote_cast_count
    FROM votes v
    GROUP BY v.userid
),
posthistory_counts AS (
    SELECT ph.userid AS user_id,
           COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
owned_posts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS posts_owned,
           SUM(p.score) AS total_post_score,
           AVG(p.score) AS avg_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
edited_posts AS (
    SELECT p.lasteditoruserid AS user_id,
           COUNT(*) AS posts_edited
    FROM posts p
    GROUP BY p.lasteditoruserid
),
user_summary AS (
    SELECT u.id AS user_id,
           u.reputation,
           COALESCE(bc.badge_count, 0) AS badge_count,
           COALESCE(cc.comment_count, 0) AS comment_count,
           COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
           COALESCE(phc.posthistory_count, 0) AS posthistory_count,
           COALESCE(op.posts_owned, 0) AS posts_owned,
           COALESCE(ep.posts_edited, 0) AS posts_edited,
           COALESCE(op.total_post_score, 0) AS total_post_score,
           COALESCE(op.avg_post_score, 0) AS avg_post_score
    FROM users u
    LEFT JOIN badge_counts bc ON bc.user_id = u.id
    LEFT JOIN comment_counts cc ON cc.user_id = u.id
    LEFT JOIN vote_counts vc ON vc.user_id = u.id
    LEFT JOIN posthistory_counts phc ON phc.user_id = u.id
    LEFT JOIN owned_posts op ON op.user_id = u.id
    LEFT JOIN edited_posts ep ON ep.user_id = u.id
)
SELECT user_id,
       reputation,
       badge_count,
       comment_count,
       vote_cast_count,
       posthistory_count,
       posts_owned,
       posts_edited,
       total_post_score,
       avg_post_score
FROM user_summary
WHERE badge_count >= 5
ORDER BY reputation DESC, badge_count DESC
LIMIT 50
