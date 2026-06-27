WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS total_posts_owned,
           AVG(score) AS avg_post_score,
           SUM(viewcount) AS total_viewcount
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT lasteditoruserid AS user_id,
           COUNT(*) AS total_posts_edited
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_comments
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_votes_cast
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS total_tags
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(p.total_posts_owned, 0) AS total_posts_owned,
       COALESCE(p.avg_post_score, 0) AS avg_post_score,
       COALESCE(p.total_viewcount, 0) AS total_viewcount,
       COALESCE(e.total_posts_edited, 0) AS total_posts_edited,
       COALESCE(c.total_comments, 0) AS total_comments,
       COALESCE(v.total_votes_cast, 0) AS total_votes_cast,
       COALESCE(b.total_badges, 0) AS total_badges,
       COALESCE(t.total_tags, 0) AS total_tags
FROM users u
LEFT JOIN user_posts   p ON p.user_id = u.id
LEFT JOIN user_edits   e ON e.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes   v ON v.user_id = u.id
LEFT JOIN user_badges  b ON b.user_id = u.id
LEFT JOIN user_tags    t ON t.user_id = u.id
ORDER BY total_posts_owned DESC, total_comments DESC
LIMIT 100
