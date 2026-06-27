-- User activity summary: reputation, content contributions, voting activity, badges, post history,
-- and link connectivity of the user's posts.
WITH user_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_views,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments,
        SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast,
        COUNT(DISTINCT postid) AS distinct_posts_voted
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_events
    FROM posthistory
    GROUP BY userid
),
user_postlinks_out AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS outgoing_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_in AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS incoming_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0)                 AS post_count,
    COALESCE(up.total_post_score, 0)          AS total_post_score,
    COALESCE(up.avg_post_score, 0)            AS avg_post_score,
    COALESCE(up.total_views, 0)               AS total_views,
    COALESCE(up.total_answers, 0)             AS total_answers,
    COALESCE(up.total_comments, 0)            AS total_comments,
    COALESCE(up.total_favorites, 0)           AS total_favorites,
    COALESCE(uc.comment_count, 0)             AS comment_count,
    COALESCE(uc.avg_comment_score, 0)         AS avg_comment_score,
    COALESCE(uvc.votes_cast, 0)               AS votes_cast,
    COALESCE(uvc.distinct_posts_voted, 0)     AS distinct_posts_voted,
    COALESCE(uvr.votes_received, 0)           AS votes_received,
    COALESCE(uvr.upvotes_received, 0)         AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0)       AS downvotes_received,
    COALESCE(ub.badge_count, 0)               AS badge_count,
    COALESCE(uph.posthistory_events, 0)       AS posthistory_events,
    COALESCE(uplo.outgoing_links, 0)          AS outgoing_links,
    COALESCE(upli.incoming_links, 0)          AS incoming_links
FROM users u
LEFT JOIN user_posts up               ON up.owneruserid = u.id
LEFT JOIN user_comments uc            ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc         ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr     ON uvr.owneruserid = u.id
LEFT JOIN user_badges ub              ON ub.userid = u.id
LEFT JOIN user_posthistory uph        ON uph.userid = u.id
LEFT JOIN user_postlinks_out uplo      ON uplo.owneruserid = u.id
LEFT JOIN user_postlinks_in upli       ON upli.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 100
