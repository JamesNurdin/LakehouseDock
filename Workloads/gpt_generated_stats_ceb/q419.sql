WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           u.creationdate,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS post_score_sum,
           COALESCE(SUM(p.viewcount), 0) AS post_view_sum
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS edited_post_count,
           COALESCE(SUM(p.score), 0) AS edited_post_score_sum
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast_count,
           COALESCE(SUM(v.votetypeid), 0) AS vote_type_sum
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received_count,
           COALESCE(SUM(v.votetypeid), 0) AS votes_received_type_sum
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.creationdate,
       up.post_count,
       up.post_score_sum,
       up.post_view_sum,
       ue.edited_post_count,
       ue.edited_post_score_sum,
       uc.comment_count,
       uc.comment_score_sum,
       uv_cast.votes_cast_count,
       uv_cast.vote_type_sum,
       uv_recv.votes_received_count,
       uv_recv.votes_received_type_sum,
       ub.badge_count
FROM user_posts up
LEFT JOIN user_edits ue       ON ue.user_id = up.user_id
LEFT JOIN user_comments uc    ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv ON uv_recv.user_id = up.user_id
LEFT JOIN user_badges ub      ON ub.user_id = up.user_id
ORDER BY up.post_count DESC
LIMIT 100
