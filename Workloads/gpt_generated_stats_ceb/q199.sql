WITH user_activity AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COALESCE(p_owned.post_count, 0) AS post_count,
        COALESCE(p_owned.total_score, 0) AS total_post_score,
        COALESCE(c_made.comment_count, 0) AS comment_count,
        COALESCE(v_cast.vote_count, 0) AS vote_cast_count,
        COALESCE(b.badge_count, 0) AS badge_count,
        COALESCE(ph.edit_count, 0) AS edit_count,
        COALESCE(pl.link_count, 0) AS postlink_count,
        COALESCE(tg.tag_excerpt_count, 0) AS tag_excerpt_count
    FROM users u
    LEFT JOIN (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_score
        FROM posts
        GROUP BY owneruserid
    ) p_owned
        ON p_owned.user_id = u.id
    LEFT JOIN (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ) c_made
        ON c_made.user_id = u.id
    LEFT JOIN (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_count
        FROM votes
        GROUP BY userid
    ) v_cast
        ON v_cast.user_id = u.id
    LEFT JOIN (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ) b
        ON b.user_id = u.id
    LEFT JOIN (
        SELECT
            userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ) ph
        ON ph.user_id = u.id
    LEFT JOIN (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT pl.id) AS link_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ) pl
        ON pl.user_id = u.id
    LEFT JOIN (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ) tg
        ON tg.user_id = u.id
)
SELECT
    user_id,
    reputation,
    post_count,
    total_post_score,
    CASE WHEN post_count > 0 THEN total_post_score / post_count ELSE NULL END AS avg_post_score,
    comment_count,
    vote_cast_count,
    badge_count,
    edit_count,
    postlink_count,
    tag_excerpt_count
FROM user_activity
ORDER BY total_post_score DESC
LIMIT 10
