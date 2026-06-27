WITH user_info AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
),
post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_posts,
        SUM(p.score) AS sum_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS sum_viewcount,
        SUM(p.favoritecount) AS sum_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS total_comments_made,
        SUM(c.score) AS sum_comment_score,
        AVG(c.score) AS avg_comment_score,
        COUNT(DISTINCT c.postid) AS distinct_posts_commented
    FROM comments c
    GROUP BY c.userid
),
vote_cast_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS total_votes_cast,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_cast,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
vote_received_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_votes_received,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_received,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges b
    GROUP BY b.userid
),
edit_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS total_edits
    FROM posthistory ph
    GROUP BY ph.userid
),
tag_excerpt_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tags_excerpted
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
postlink_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_postlinks_out,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_posts
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ui.user_id,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(ps.sum_post_score, 0) AS sum_post_score,
    COALESCE(ps.avg_post_score, 0.0) AS avg_post_score,
    COALESCE(ps.sum_viewcount, 0) AS sum_viewcount,
    COALESCE(ps.sum_favoritecount, 0) AS sum_favoritecount,
    COALESCE(cs.total_comments_made, 0) AS total_comments_made,
    COALESCE(cs.sum_comment_score, 0) AS sum_comment_score,
    COALESCE(cs.avg_comment_score, 0.0) AS avg_comment_score,
    COALESCE(cs.distinct_posts_commented, 0) AS distinct_posts_commented,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(bs.total_badges, 0) AS total_badges,
    COALESCE(es.total_edits, 0) AS total_edits,
    COALESCE(ts.distinct_tags_excerpted, 0) AS distinct_tags_excerpted,
    COALESCE(pls.total_postlinks_out, 0) AS total_postlinks_out,
    COALESCE(pls.distinct_related_posts, 0) AS distinct_related_posts
FROM user_info ui
LEFT JOIN post_stats ps ON ui.user_id = ps.user_id
LEFT JOIN comment_stats cs ON ui.user_id = cs.user_id
LEFT JOIN vote_cast_stats vc ON ui.user_id = vc.user_id
LEFT JOIN vote_received_stats vr ON ui.user_id = vr.user_id
LEFT JOIN badge_stats bs ON ui.user_id = bs.user_id
LEFT JOIN edit_stats es ON ui.user_id = es.user_id
LEFT JOIN tag_excerpt_stats ts ON ui.user_id = ts.user_id
LEFT JOIN postlink_stats pls ON ui.user_id = pls.user_id
ORDER BY ui.reputation DESC
LIMIT 100
