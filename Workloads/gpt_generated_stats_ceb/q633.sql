WITH
    -- Aggregated post metrics per user (owner)
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_score,
            AVG(score) AS avg_score,
            SUM(viewcount) AS total_views,
            SUM(favoritecount) AS total_favorites,
            SUM(answercount) AS total_answers
        FROM posts
        GROUP BY owneruserid
    ),
    -- Count of comments authored by each user
    comments_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    -- Count of comments received on a user's posts
    comments_on_user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comments_received
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Count of votes cast by each user
    votes_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    -- Count of votes received on a user's posts
    votes_received_by_user AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Count of badges earned by each user
    badges_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    -- Count of post‑history events performed by each user
    posthistory_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_events
        FROM posthistory
        GROUP BY userid
    ),
    -- Count of post‑history events that target a user's posts (via posthistorytypeid)
    posthistory_on_user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posthistory_on_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    -- Count of outgoing post links from a user's posts
    postlinks_outgoing AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS links_out
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Count of incoming post links to a user's posts
    postlinks_incoming AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS links_in
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0)               AS post_count,
    COALESCE(up.total_score, 0)              AS total_score,
    COALESCE(up.avg_score, 0)                AS avg_score,
    COALESCE(up.total_views, 0)              AS total_views,
    COALESCE(up.total_favorites, 0)          AS total_favorites,
    COALESCE(up.total_answers, 0)            AS total_answers,
    COALESCE(cbu.comment_count, 0)           AS comment_count,
    COALESCE(cup.comments_received, 0)       AS comments_received,
    COALESCE(vbu.votes_cast, 0)              AS votes_cast,
    COALESCE(vru.votes_received, 0)          AS votes_received,
    COALESCE(bb.badge_count, 0)              AS badge_count,
    COALESCE(phb.posthistory_events, 0)      AS posthistory_events,
    COALESCE(pho.posthistory_on_posts, 0)    AS posthistory_on_posts,
    COALESCE(plo.links_out, 0)               AS links_out,
    COALESCE(pli.links_in, 0)                AS links_in
FROM users u
LEFT JOIN user_posts up                ON u.id = up.user_id
LEFT JOIN comments_by_user cbu          ON u.id = cbu.user_id
LEFT JOIN comments_on_user_posts cup    ON u.id = cup.user_id
LEFT JOIN votes_by_user vbu             ON u.id = vbu.user_id
LEFT JOIN votes_received_by_user vru    ON u.id = vru.user_id
LEFT JOIN badges_by_user bb             ON u.id = bb.user_id
LEFT JOIN posthistory_by_user phb       ON u.id = phb.user_id
LEFT JOIN posthistory_on_user_posts pho ON u.id = pho.user_id
LEFT JOIN postlinks_outgoing plo         ON u.id = plo.user_id
LEFT JOIN postlinks_incoming pli        ON u.id = pli.user_id
ORDER BY u.reputation DESC
LIMIT 100
