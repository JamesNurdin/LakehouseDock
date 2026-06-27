WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        p.id AS post_id,
        p.score AS post_score
    FROM posts p
),
post_comments AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.postid
),
post_votes AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count
    FROM votes v
    GROUP BY v.postid
),
post_tags AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    GROUP BY t.excerptpostid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_aggregates AS (
    SELECT
        up.user_id,
        COUNT(up.post_id) AS post_count,
        SUM(up.post_score) AS total_post_score,
        SUM(COALESCE(pc.comment_count, 0)) AS total_comment_count,
        SUM(COALESCE(pc.comment_score_sum, 0)) AS total_comment_score_sum,
        SUM(COALESCE(pv.vote_count, 0)) AS total_vote_count,
        SUM(COALESCE(pt.tag_count, 0)) AS total_tag_count
    FROM user_posts up
    LEFT JOIN post_comments pc ON up.post_id = pc.post_id
    LEFT JOIN post_votes pv ON up.post_id = pv.post_id
    LEFT JOIN post_tags pt ON up.post_id = pt.post_id
    GROUP BY up.user_id
)
SELECT
    u.id AS user_id,
    u.reputation,
    ua.post_count,
    ua.total_post_score,
    ua.total_comment_count,
    CASE
        WHEN ua.total_comment_count = 0 THEN NULL
        ELSE ua.total_comment_score_sum / ua.total_comment_count
    END AS avg_comment_score,
    ua.total_vote_count,
    ua.total_tag_count,
    COALESCE(ub.badge_count, 0) AS badge_count
FROM user_aggregates ua
JOIN users u ON ua.user_id = u.id
LEFT JOIN user_badges ub ON ua.user_id = ub.user_id
ORDER BY ua.total_post_score DESC
LIMIT 10
