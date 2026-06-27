WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            MAX(creationdate) AS last_post_date
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            MAX(creationdate) AS last_comment_date
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_count,
            MAX(creationdate) AS last_vote_date
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count,
            MAX(date) AS last_badge_date
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            userid,
            COUNT(*) AS edit_count,
            MAX(creationdate) AS last_edit_date
        FROM posthistory
        GROUP BY userid
    ),
    user_links AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS link_count,
            MAX(l.creationdate) AS last_link_date
        FROM postlinks l
        JOIN posts p ON l.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(l.link_count, 0) AS link_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    (
        COALESCE(p.post_count, 0) * 5
        + COALESCE(c.comment_count, 0) * 2
        + COALESCE(v.vote_count, 0) * 1
        + COALESCE(b.badge_count, 0) * 3
        + COALESCE(e.edit_count, 0) * 2
        + COALESCE(l.link_count, 0) * 1
        + COALESCE(tg.tag_count, 0) * 1
    ) AS activity_score,
    GREATEST(
        COALESCE(p.last_post_date, TIMESTAMP '1970-01-01 00:00:00 UTC'),
        COALESCE(c.last_comment_date, TIMESTAMP '1970-01-01 00:00:00 UTC'),
        COALESCE(v.last_vote_date, TIMESTAMP '1970-01-01 00:00:00 UTC'),
        COALESCE(b.last_badge_date, TIMESTAMP '1970-01-01 00:00:00 UTC'),
        COALESCE(e.last_edit_date, TIMESTAMP '1970-01-01 00:00:00 UTC'),
        COALESCE(l.last_link_date, TIMESTAMP '1970-01-01 00:00:00 UTC')
    ) AS last_activity_date
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_edits e ON e.userid = u.id
LEFT JOIN user_links l ON l.userid = u.id
LEFT JOIN user_tags tg ON tg.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
