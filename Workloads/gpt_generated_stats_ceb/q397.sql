WITH
    user_posts AS (
        SELECT
            owneruserid,
            COUNT(*) AS total_posts,
            SUM(score) AS total_score,
            AVG(score) AS avg_score,
            SUM(viewcount) AS total_views,
            AVG(viewcount) AS avg_views,
            COUNT(CASE WHEN posttypeid = 1 THEN 1 END) AS total_questions,
            COUNT(CASE WHEN posttypeid = 2 THEN 1 END) AS total_answers
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid, COUNT(*) AS total_comments_made
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid, COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid, COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT userid, COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    user_tags AS (
        SELECT p.owneruserid, COUNT(DISTINCT t.id) AS total_tags
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT userid, COUNT(*) AS total_edits
        FROM posthistory
        GROUP BY userid
    ),
    user_links_outgoing AS (
        SELECT p.owneruserid, COUNT(*) AS total_outgoing_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_links_incoming AS (
        SELECT p.owneruserid, COUNT(*) AS total_incoming_links
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_score, 0) AS avg_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.avg_views, 0) AS avg_views,
    COALESCE(up.total_questions, 0) AS total_questions,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(uc.total_comments_made, 0) AS total_comments_made,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(ut.total_tags, 0) AS total_tags,
    COALESCE(ue.total_edits, 0) AS total_edits,
    COALESCE(ulo.total_outgoing_links, 0) AS total_outgoing_links,
    COALESCE(uli.total_incoming_links, 0) AS total_incoming_links
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_links_outgoing ulo ON ulo.owneruserid = u.id
LEFT JOIN user_links_incoming uli ON uli.owneruserid = u.id
WHERE ub.total_badges > 0
ORDER BY total_score DESC
LIMIT 10
