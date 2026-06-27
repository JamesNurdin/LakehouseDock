WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_views,
        COUNT(DISTINCT p.id) FILTER (WHERE p.owneruserid = u.id) AS owned_post_count,
        COUNT(DISTINCT p.id) FILTER (WHERE p.lasteditoruserid = u.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id OR p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count,
        COUNT(DISTINCT p.id) AS distinct_posts_affected
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS postlink_count,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id OR p.lasteditoruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.post_count,
    up.total_post_score,
    up.total_views,
    up.owned_post_count,
    up.edited_post_count,
    uc.comment_count,
    uc.total_comment_score,
    uv.votes_cast,
    uv.upvotes_cast,
    uv.downvotes_cast,
    ub.badge_count,
    ut.tag_count,
    uph.posthistory_count,
    uph.distinct_posts_affected,
    upl.postlink_count,
    upl.distinct_related_posts
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes uv ON uv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY up.total_post_score DESC, up.post_count DESC
LIMIT 100
