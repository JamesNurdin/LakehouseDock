WITH user_posts AS (
    SELECT
        p.owneruserid,
        p.id AS post_id,
        p.score,
        p.creationdate
    FROM posts p
),
post_comments AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.postid
),
post_votes AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    GROUP BY v.postid
),
outgoing_links AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS outgoing_links
    FROM postlinks pl
    GROUP BY pl.postid
),
incoming_links AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS incoming_links
    FROM postlinks pl
    GROUP BY pl.relatedpostid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(up.post_id) AS total_posts,
    COALESCE(SUM(up.score), 0) / NULLIF(COUNT(up.post_id), 0) AS avg_post_score,
    COALESCE(SUM(pc.comment_count), 0) AS total_comments,
    COALESCE(SUM(pv.vote_count), 0) AS total_votes,
    COALESCE(SUM(pv.upvote_count), 0) AS total_upvotes,
    COALESCE(SUM(pv.downvote_count), 0) AS total_downvotes,
    COALESCE(SUM(ol.outgoing_links), 0) AS total_outgoing_links,
    COALESCE(SUM(il.incoming_links), 0) AS total_incoming_links
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN post_comments pc ON pc.post_id = up.post_id
LEFT JOIN post_votes pv ON pv.post_id = up.post_id
LEFT JOIN outgoing_links ol ON ol.post_id = up.post_id
LEFT JOIN incoming_links il ON il.post_id = up.post_id
GROUP BY u.id, u.reputation
ORDER BY total_posts DESC
LIMIT 100
