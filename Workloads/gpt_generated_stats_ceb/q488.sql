WITH owned_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.commentcount), 0) AS total_comments_received,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
edited_posts AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edited_post_count
    FROM posts p
    GROUP BY p.lasteditoruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast
    FROM votes v
    GROUP BY v.userid
),
post_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_received,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS postlinks_outgoing,
        COUNT(pl_related.id) AS postlinks_incoming
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    LEFT JOIN postlinks pl_related ON pl_related.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(op.post_count, 0) AS posts_owned,
    COALESCE(op.total_score, 0) AS owned_posts_score,
    COALESCE(op.total_views, 0) AS owned_posts_views,
    COALESCE(op.total_answers, 0) AS owned_posts_answers,
    COALESCE(op.total_comments_received, 0) AS owned_posts_comments_received,
    COALESCE(op.total_favorites, 0) AS owned_posts_favorites,
    COALESCE(ep.edited_post_count, 0) AS posts_edited,
    COALESCE(uc.comment_count, 0) AS comments_made,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.upvote_cast, 0) AS upvotes_cast,
    COALESCE(uv.downvote_cast, 0) AS downvotes_cast,
    COALESCE(pvr.votes_received, 0) AS votes_received,
    COALESCE(pvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(pvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badges_earned,
    COALESCE(uph.posthistory_count, 0) AS posthistory_entries,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tags_used,
    COALESCE(pl.postlinks_outgoing, 0) AS postlinks_outgoing,
    COALESCE(pl.postlinks_incoming, 0) AS postlinks_incoming
FROM users u
LEFT JOIN owned_posts op ON op.user_id = u.id
LEFT JOIN edited_posts ep ON ep.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN post_votes_received pvr ON pvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
WHERE u.reputation > 0
ORDER BY owned_posts_score DESC
LIMIT 100
