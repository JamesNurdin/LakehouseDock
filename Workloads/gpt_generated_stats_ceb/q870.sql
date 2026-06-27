WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given,
            SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    )
SELECT
    u.id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_given, 0) AS upvote_given,
    COALESCE(v.downvote_given, 0) AS downvote_given,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(v.vote_count, 0) + COALESCE(b.badge_count, 0) + COALESCE(e.edit_count, 0) + COALESCE(t.tag_count, 0)) AS total_activity
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_tags t ON t.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_edits e ON e.userid = u.id
ORDER BY total_activity DESC
LIMIT 100
