WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.commentcount) AS total_comments_received,
            SUM(p.viewcount) AS total_views,
            SUM(p.answercount) AS total_answers,
            SUM(p.favoritecount) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(v.id) AS votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(b.id) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS linked_posts_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
        UNION ALL
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS linked_posts_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_agg AS (
        SELECT
            user_id,
            SUM(linked_posts_count) AS total_linked_posts
        FROM postlinks_counts
        GROUP BY user_id
    ),
    post_edits AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_comments_received, 0) AS total_comments_received,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(pl.total_linked_posts, 0) AS total_linked_posts,
    COALESCE(pe.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN postlinks_agg pl ON pl.user_id = u.id
LEFT JOIN post_edits pe ON pe.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
