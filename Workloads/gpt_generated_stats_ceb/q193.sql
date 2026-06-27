WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_posts,
        COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS total_answers,
        AVG(p.score) AS avg_post_score,
        SUM(p.favoritecount) AS sum_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS total_comments
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS total_votes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges b
    GROUP BY b.userid
),
user_tag_excerpts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_tag_excerpts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_post_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_post_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.sum_favoritecount, 0) AS sum_favoritecount,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ut.total_tag_excerpts, 0) AS total_tag_excerpts,
    COALESCE(up_links.total_post_links, 0) AS total_post_links,
    (COALESCE(up.total_posts, 0) * 5) +
    (COALESCE(uc.total_comments, 0) * 2) +
    (COALESCE(uvc.total_votes_cast, 0) * 1) +
    (COALESCE(uvr.total_votes_received, 0) * 3) +
    (COALESCE(ub.total_badges, 0) * 4) +
    (COALESCE(ut.total_tag_excerpts, 0) * 2) +
    (COALESCE(up_links.total_post_links, 0) * 1) AS activity_score
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tag_excerpts ut ON ut.user_id = u.id
LEFT JOIN user_post_links up_links ON up_links.user_id = u.id
WHERE u.reputation > 0
ORDER BY activity_score DESC
LIMIT 10
