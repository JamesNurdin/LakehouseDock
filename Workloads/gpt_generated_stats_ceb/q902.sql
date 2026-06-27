/*
  Top 10 users by total score of the posts they authored, with additional engagement metrics:
  - number of posts authored
  - average post score
  - total votes received on their posts
  - total comments on their posts and the average comment score per comment
  - total distinct tags appearing in their posts (counted per post)
*/
WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        p.score AS post_score,
        COUNT(DISTINCT v.id) AS vote_count,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.id, p.owneruserid, p.score
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(pm.post_id) AS total_posts,
    SUM(pm.post_score) AS total_post_score,
    AVG(pm.post_score) AS avg_post_score,
    SUM(pm.vote_count) AS total_votes_received,
    SUM(pm.comment_count) AS total_comments_on_posts,
    SUM(pm.comment_score_sum) AS total_comment_score_on_posts,
    SUM(pm.comment_score_sum) / NULLIF(SUM(pm.comment_count), 0) AS avg_comment_score_per_comment,
    SUM(pm.tag_count) AS total_tags_on_posts
FROM post_metrics pm
JOIN users u ON u.id = pm.owner_user_id
GROUP BY u.id, u.reputation
ORDER BY total_post_score DESC
LIMIT 10
