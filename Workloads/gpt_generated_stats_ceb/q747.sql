WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(score) AS total_post_score,
            SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
            SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_written AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments_written,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    user_tags_excerpt AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS total_tags_excerpt
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_days_to_first_comment AS (
        SELECT
            p.owneruserid AS user_id,
            AVG(date_diff('day', p.creationdate, c.first_comment_date)) AS avg_days_to_first_comment
        FROM (
            SELECT
                postid,
                MIN(creationdate) AS first_comment_date
            FROM comments
            GROUP BY postid
        ) c
        JOIN posts p ON p.id = c.postid
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_posthistory_events
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_post_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_questions, 0) AS total_questions,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(uc.total_comments_written, 0) AS total_comments_written,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(t.total_tags_excerpt, 0) AS total_tags_excerpt,
    ud.avg_days_to_first_comment,
    COALESCE(ph.total_posthistory_events, 0) AS total_posthistory_events,
    COALESCE(pl.total_post_links, 0) AS total_post_links
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_written uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_tags_excerpt t ON t.user_id = u.id
LEFT JOIN user_days_to_first_comment ud ON ud.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
