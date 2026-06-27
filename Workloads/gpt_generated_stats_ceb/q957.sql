WITH
post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_post_views,
        SUM(p.answercount) AS total_answers,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
badge_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
vote_cast_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
vote_received_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
posthistory_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS post_history_count
    FROM posthistory ph
    GROUP BY ph.userid
),
postlinks_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_links_count
    FROM postlinks pl
    JOIN posts p
        ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ua.*,
    row_number() OVER (ORDER BY ua.total_activity DESC) AS activity_rank
FROM (
    SELECT
        u.id AS user_id,
        u.reputation,
        COALESCE(ps.post_count, 0) AS post_count,
        COALESCE(ps.total_post_score, 0) AS total_post_score,
        COALESCE(ps.total_post_views, 0) AS total_post_views,
        COALESCE(ps.total_answers, 0) AS total_answers,
        COALESCE(ps.tag_count, 0) AS tag_count,
        COALESCE(cs.comment_count, 0) AS comment_count,
        COALESCE(bs.badge_count, 0) AS badge_count,
        COALESCE(vcs.votes_cast_count, 0) AS votes_cast_count,
        COALESCE(vrs.votes_received_count, 0) AS votes_received_count,
        COALESCE(phs.post_history_count, 0) AS post_history_count,
        COALESCE(pls.post_links_count, 0) AS post_links_count,
        (COALESCE(ps.post_count, 0) +
         COALESCE(cs.comment_count, 0) +
         COALESCE(bs.badge_count, 0) +
         COALESCE(vcs.votes_cast_count, 0) +
         COALESCE(vrs.votes_received_count, 0) +
         COALESCE(phs.post_history_count, 0) +
         COALESCE(pls.post_links_count, 0)) AS total_activity
    FROM users u
    LEFT JOIN post_stats ps
        ON ps.user_id = u.id
    LEFT JOIN comment_stats cs
        ON cs.user_id = u.id
    LEFT JOIN badge_stats bs
        ON bs.user_id = u.id
    LEFT JOIN vote_cast_stats vcs
        ON vcs.user_id = u.id
    LEFT JOIN vote_received_stats vrs
        ON vrs.user_id = u.id
    LEFT JOIN posthistory_stats phs
        ON phs.user_id = u.id
    LEFT JOIN postlinks_stats pls
        ON pls.user_id = u.id
) ua
ORDER BY ua.total_activity DESC
LIMIT 50
