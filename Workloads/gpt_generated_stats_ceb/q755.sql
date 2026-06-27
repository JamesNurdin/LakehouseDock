WITH post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
vote_cast_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
vote_received_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
tag_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_events
    FROM posthistory ph
    GROUP BY ph.userid
),
postlinks_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS post_links_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
)
SELECT
    u.user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_score, 0) AS total_post_score,
    COALESCE(p.total_views, 0) AS total_post_views,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(ph.posthistory_events, 0) AS posthistory_events,
    COALESCE(pl.post_links_count, 0) AS post_links_count
FROM user_base u
LEFT JOIN post_stats p ON p.user_id = u.user_id
LEFT JOIN comment_stats c ON c.user_id = u.user_id
LEFT JOIN vote_cast_stats vc ON vc.user_id = u.user_id
LEFT JOIN vote_received_stats vr ON vr.user_id = u.user_id
LEFT JOIN badge_stats b ON b.user_id = u.user_id
LEFT JOIN tag_stats t ON t.user_id = u.user_id
LEFT JOIN posthistory_stats ph ON ph.user_id = u.user_id
LEFT JOIN postlinks_stats pl ON pl.user_id = u.user_id
ORDER BY u.reputation DESC
LIMIT 100
