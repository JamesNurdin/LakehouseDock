WITH user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
),
badge_counts AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
post_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        AVG(p.score) AS avg_post_score,
        AVG(p.viewcount) AS avg_view_count,
        SUM(p.commentcount) AS total_comments_on_posts,
        SUM(p.favoritecount) AS total_favorites,
        SUM(p.answercount) AS total_answers
    FROM posts p
    GROUP BY p.owneruserid
),
post_edits AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
vote_casts AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
vote_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
comment_counts AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comments_made
    FROM comments c
    GROUP BY c.userid
),
posthistory_counts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_events
    FROM posthistory ph
    GROUP BY ph.userid
),
tag_excerpts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
link_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(pc.avg_post_score, 0) AS avg_post_score,
    COALESCE(pc.avg_view_count, 0) AS avg_view_count,
    COALESCE(pc.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(pc.total_favorites, 0) AS total_favorites,
    COALESCE(pc.total_answers, 0) AS total_answers,
    COALESCE(pe.edit_count, 0) AS edit_count,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(cc.comments_made, 0) AS comments_made,
    COALESCE(phc.posthistory_events, 0) AS posthistory_events,
    COALESCE(te.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(lc.postlink_count, 0) AS postlink_count
FROM user_base ub
LEFT JOIN badge_counts bc ON bc.user_id = ub.user_id
LEFT JOIN post_counts pc ON pc.user_id = ub.user_id
LEFT JOIN post_edits pe ON pe.user_id = ub.user_id
LEFT JOIN vote_casts vc ON vc.user_id = ub.user_id
LEFT JOIN vote_received vr ON vr.user_id = ub.user_id
LEFT JOIN comment_counts cc ON cc.user_id = ub.user_id
LEFT JOIN posthistory_counts phc ON phc.user_id = ub.user_id
LEFT JOIN tag_excerpts te ON te.user_id = ub.user_id
LEFT JOIN link_counts lc ON lc.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100
