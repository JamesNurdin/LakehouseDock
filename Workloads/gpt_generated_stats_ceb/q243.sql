WITH
    users_base AS (
        SELECT
            id AS user_id,
            reputation
        FROM users
    ),
    badge_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_metrics AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(answercount), 0) AS total_answers,
            COALESCE(AVG(score), 0) AS avg_post_score,
            COALESCE(SUM(viewcount), 0) AS total_views,
            COALESCE(SUM(favoritecount), 0) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    comment_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_written_count
        FROM comments
        GROUP BY userid
    ),
    votes_cast_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    votes_received_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received_count
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    post_history_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS post_history_actions
        FROM posthistory
        GROUP BY userid
    ),
    tag_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tags_used
        FROM posts p
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    post_links_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT pl.id) AS post_links_count
        FROM posts p
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.user_id,
    u.reputation,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.total_favorites, 0) AS total_favorites,
    COALESCE(c.comment_written_count, 0) AS comment_written_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ph.post_history_actions, 0) AS post_history_actions,
    COALESCE(t.distinct_tags_used, 0) AS distinct_tags_used,
    COALESCE(pl.post_links_count, 0) AS post_links_count
FROM users_base u
LEFT JOIN badge_counts b ON b.user_id = u.user_id
LEFT JOIN post_metrics p ON p.user_id = u.user_id
LEFT JOIN comment_counts c ON c.user_id = u.user_id
LEFT JOIN votes_cast_counts vc ON vc.user_id = u.user_id
LEFT JOIN votes_received_counts vr ON vr.user_id = u.user_id
LEFT JOIN post_history_counts ph ON ph.user_id = u.user_id
LEFT JOIN tag_counts t ON t.user_id = u.user_id
LEFT JOIN post_links_counts pl ON pl.user_id = u.user_id
ORDER BY badge_count DESC, u.reputation DESC
LIMIT 10
