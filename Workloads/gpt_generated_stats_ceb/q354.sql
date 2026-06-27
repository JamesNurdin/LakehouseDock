WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        SUM(p.viewcount) AS total_views,
        AVG(p.answercount) AS avg_answercount,
        AVG(p.commentcount) AS avg_commentcount,
        SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments_made AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comments_made
    FROM comments c
    GROUP BY c.userid
),
user_comments_on_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comments_on_posts
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_edits AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlink_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(up.avg_answercount, 0) AS avg_answer_count,
    COALESCE(up.avg_commentcount, 0) AS avg_comment_count,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(co.comments_on_posts, 0) AS comments_on_posts,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(tg.tag_count, 0) AS tag_excerpt_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made cm ON cm.user_id = u.id
LEFT JOIN user_comments_on_posts co ON co.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_edits e ON e.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
LEFT JOIN user_tags tg ON tg.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
ORDER BY post_count DESC, user_id
LIMIT 100
