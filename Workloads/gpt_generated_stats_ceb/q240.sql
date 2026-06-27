WITH posts_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score
    FROM posts p
    GROUP BY p.owneruserid
),
votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received,
        COUNT(*) FILTER (WHERE v.votetypeid = 1) AS upvotes_received,
        COUNT(*) FILTER (WHERE v.votetypeid = 2) AS downvotes_received
    FROM votes v
    JOIN posts p ON p.id = v.postid
    GROUP BY p.owneruserid
),
votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast,
        COUNT(*) FILTER (WHERE v.votetypeid = 1) AS upvotes_cast,
        COUNT(*) FILTER (WHERE v.votetypeid = 2) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
related_posts_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS related_post_links,
        AVG(p_rel.score) AS avg_related_score
    FROM postlinks pl
    JOIN posts p ON p.id = pl.postid
    JOIN posts p_rel ON p_rel.id = pl.relatedpostid
    GROUP BY p.owneruserid
),
last_editor_rep AS (
    SELECT
        p.owneruserid AS user_id,
        AVG(u_editor.reputation) AS avg_last_editor_rep
    FROM posts p
    JOIN users u_editor ON u_editor.id = p.lasteditoruserid
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pa.post_count, 0) AS total_posts,
    COALESCE(pa.total_score, 0) AS total_score,
    COALESCE(pa.avg_score, 0) AS avg_score,
    COALESCE(vr.votes_received, 0) AS total_votes_received,
    COALESCE(vr.upvotes_received, 0) AS total_upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS total_downvotes_received,
    COALESCE(vc.votes_cast, 0) AS total_votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS total_upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS total_downvotes_cast,
    COALESCE(rps.related_post_links, 0) AS total_related_posts,
    COALESCE(rps.avg_related_score, 0) AS avg_related_post_score,
    COALESCE(le.avg_last_editor_rep, 0) AS avg_last_editor_reputation
FROM users u
LEFT JOIN posts_agg pa ON pa.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN votes_cast vc ON vc.user_id = u.id
LEFT JOIN related_posts_stats rps ON rps.user_id = u.id
LEFT JOIN last_editor_rep le ON le.user_id = u.id
ORDER BY total_posts DESC
LIMIT 50
