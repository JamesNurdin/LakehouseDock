/*
   Analytical query: user activity and reputation summary with ranking.
   Joins only the allowed tables and columns, aggregates per user, and ranks the top users.
*/
WITH user_badge_counts AS (
    SELECT b.userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_post_stats AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_count,
           AVG(p.score) AS avg_post_score,
           SUM(p.viewcount) AS total_views,
           SUM(p.favoritecount) AS total_favoritecount,
           SUM(p.answercount) AS total_answercount,
           SUM(p.commentcount) AS total_commentcount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comment_counts AS (
    SELECT c.userid AS user_id,
           COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_vote_cast_counts AS (
    SELECT v.userid AS user_id,
           COUNT(*) AS vote_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_vote_received_counts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS vote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_counts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ROW_NUMBER() OVER (ORDER BY (u.reputation + COALESCE(bc.badge_count, 0) * 1000) DESC) AS user_rank,
    u.id AS user_id,
    u.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(ps.total_views, 0) AS total_views,
    COALESCE(ps.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(ps.total_answercount, 0) AS total_answercount,
    COALESCE(ps.total_commentcount, 0) AS total_commentcount,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vr.vote_received_count, 0) AS vote_received_count,
    COALESCE(tc.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_badge_counts bc ON bc.user_id = u.id
LEFT JOIN user_post_stats ps ON ps.user_id = u.id
LEFT JOIN user_comment_counts cc ON cc.user_id = u.id
LEFT JOIN user_vote_cast_counts vc ON vc.user_id = u.id
LEFT JOIN user_vote_received_counts vr ON vr.user_id = u.id
LEFT JOIN user_tag_counts tc ON tc.user_id = u.id
ORDER BY user_rank
LIMIT 100
