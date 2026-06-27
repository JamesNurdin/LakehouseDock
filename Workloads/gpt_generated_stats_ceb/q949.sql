WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_post_views,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_written AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comments_written
        FROM comments
        GROUP BY userid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comments_received
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory_written AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_written
        FROM posthistory
        GROUP BY userid
    ),
    user_posthistory_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posthistory_received
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS edits_made
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_postlinks_created AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlinks_created
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlinks_received
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(ucw.comments_written, 0) AS comments_written,
    COALESCE(ucr.comments_received, 0) AS comments_received,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(uphw.posthistory_written, 0) AS posthistory_written,
    COALESCE(uphr.posthistory_received, 0) AS posthistory_received,
    COALESCE(ue.edits_made, 0) AS edits_made,
    COALESCE(upc.postlinks_created, 0) AS postlinks_created,
    COALESCE(upr.postlinks_received, 0) AS postlinks_received
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_written ucw ON ucw.user_id = u.id
LEFT JOIN user_comments_received ucr ON ucr.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_posthistory_written uphw ON uphw.user_id = u.id
LEFT JOIN user_posthistory_received uphr ON uphr.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_postlinks_created upc ON upc.user_id = u.id
LEFT JOIN user_postlinks_received upr ON upr.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
