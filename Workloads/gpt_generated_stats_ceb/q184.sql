WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS post_count,
           AVG(p.score) AS avg_post_score,
           SUM(p.viewcount) AS total_views,
           SUM(p.favoritecount) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           AVG(c.score) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_count,
           COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS upvote_count,
           COUNT(CASE WHEN v.votetypeid = 3 THEN 1 END) AS downvote_count
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_tag_excerpts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(t.id) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT up.user_id,
       up.reputation,
       up.post_count,
       up.avg_post_score,
       up.total_views,
       up.total_favorites,
       uc.comment_count,
       uc.avg_comment_score,
       uv.vote_count,
       uv.upvote_count,
       uv.downvote_count,
       ue.edited_post_count,
       COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes uv ON uv.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
