WITH user_posts AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS total_posts,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_post_views,
        SUM(p.favoritecount) AS total_favoritecount,
        SUM(p.answercount) AS total_answercount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid,
        COUNT(*) AS total_comments_written
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid,
        COUNT(*) AS total_votes_cast
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid,
        COUNT(*) AS total_badges
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid,
        COUNT(*) AS total_post_edits
    FROM posthistory ph
    GROUP BY ph.userid
),
user_postlinks AS (
    SELECT
        p.owneruserid,
        COUNT(pl.id) AS total_post_links
    FROM posts p
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid,
        COUNT(t.id) AS total_tags
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_votes_received AS (
    SELECT
        p.owneruserid,
        COUNT(v.id) AS total_votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_received,
        SUM(v.bountyamount) AS total_bounty_received
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(uc.total_comments_written, 0) AS total_comments_written,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(uph.total_post_edits, 0) AS total_post_edits,
    COALESCE(ul.total_post_links, 0) AS total_post_links,
    COALESCE(ut.total_tags, 0) AS total_tags,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(uvr.up_votes_received, 0) AS up_votes_received,
    COALESCE(uvr.down_votes_received, 0) AS down_votes_received,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_postlinks ul ON ul.owneruserid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 10
