WITH
    -- Posts authored by each user
    user_posts AS (
        SELECT
            owneruserid,
            COUNT(*) AS total_posts,
            SUM(answercount) AS total_answers,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    -- Comments made by each user
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS total_comments_made
        FROM comments
        GROUP BY userid
    ),
    -- Votes cast by each user
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    -- Votes received on a user's posts
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS total_votes_received
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Tag excerpts linked to a user's posts
    user_tag_excerpts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(t.id) AS total_tags_excerpts
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    -- Post‑history events performed by each user
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS total_posthistory_events
        FROM posthistory
        GROUP BY userid
    ),
    -- Outgoing post links from a user's posts
    user_postlinks_outgoing AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(pl.id) AS total_postlinks_outgoing
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Incoming post links to a user's posts
    user_postlinks_incoming AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(pl.id) AS total_postlinks_incoming
        FROM posts p
        JOIN postlinks pl ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(uc.total_comments_made, 0) AS total_comments_made,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(ute.total_tags_excerpts, 0) AS total_tags_excerpts,
    COALESCE(uph.total_posthistory_events, 0) AS total_posthistory_events,
    COALESCE(uplo.total_postlinks_outgoing, 0) AS total_postlinks_outgoing,
    COALESCE(upli.total_postlinks_incoming, 0) AS total_postlinks_incoming
FROM users u
LEFT JOIN user_posts up      ON up.owneruserid = u.id
LEFT JOIN user_comments uc   ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_tag_excerpts ute ON ute.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_postlinks_outgoing uplo ON uplo.userid = u.id
LEFT JOIN user_postlinks_incoming upli ON upli.userid = u.id
ORDER BY total_posts DESC
LIMIT 100
