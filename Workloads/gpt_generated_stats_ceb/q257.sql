WITH user_post_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count,
        COALESCE(SUM(p.commentcount), 0) AS total_comment_count,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comment_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_vote_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_received_votes AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badge_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_history_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS history_events,
        COUNT(DISTINCT ph.postid) AS distinct_posts_edited
    FROM posthistory ph
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
),
user_tag_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_link_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS link_count
    FROM posts p
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uv.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(urv.votes_received, 0) AS votes_received,
    COALESCE(urv.upvotes_received, 0) AS upvotes_received,
    COALESCE(urv.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uh.history_events, 0) AS history_events,
    COALESCE(uh.distinct_posts_edited, 0) AS distinct_posts_edited,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(ul.link_count, 0) AS link_count
FROM users u
LEFT JOIN user_post_stats up
    ON up.user_id = u.id
LEFT JOIN user_comment_stats uc
    ON uc.user_id = u.id
LEFT JOIN user_vote_stats uv
    ON uv.user_id = u.id
LEFT JOIN user_received_votes urv
    ON urv.user_id = u.id
LEFT JOIN user_badge_stats ub
    ON ub.user_id = u.id
LEFT JOIN user_history_stats uh
    ON uh.user_id = u.id
LEFT JOIN user_tag_stats ut
    ON ut.user_id = u.id
LEFT JOIN user_link_stats ul
    ON ul.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
