WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_posts_lastedited AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(*) AS edited_post_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS vote_count,
        SUM(v.bountyamount) AS total_bounty
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_linked_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT pl.id) AS linked_post_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_count AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.total_bounty, 0) AS total_bounty,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ul.linked_post_count, 0) AS linked_post_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    (
        COALESCE(up.post_count, 0) * 2
        + COALESCE(uc.comment_count, 0)
        + COALESCE(uv.vote_count, 0)
        + COALESCE(ub.badge_count, 0)
    ) AS activity_score
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_posts_lastedited ue ON ue.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_linked_posts ul ON ul.userid = u.id
LEFT JOIN user_tag_count ut ON ut.userid = u.id
ORDER BY u.reputation DESC, activity_score DESC
LIMIT 20
