WITH posts_by_user AS (
    SELECT owneruserid,
        COUNT(*) AS total_posts,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(AVG(score), 0) AS avg_post_score,
        COALESCE(SUM(viewcount), 0) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
comments_made_by_user AS (
    SELECT userid,
        COUNT(*) AS total_comments_made
    FROM comments
    GROUP BY userid
),
comments_received_by_user AS (
    SELECT p.owneruserid,
        COUNT(*) AS total_comments_received
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
votes_cast_by_user AS (
    SELECT userid,
        COUNT(*) AS total_votes_cast
    FROM votes
    GROUP BY userid
),
votes_received_by_user AS (
    SELECT p.owneruserid,
        COUNT(*) AS total_votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badges_by_user AS (
    SELECT userid,
        COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
posthistory_by_user AS (
    SELECT userid,
        COUNT(*) AS total_posthistory
    FROM posthistory
    GROUP BY userid
),
postlinks_by_postid AS (
    SELECT p.owneruserid,
        COUNT(*) AS total_postlinks
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
postlinks_by_relatedpostid AS (
    SELECT p.owneruserid,
        COUNT(*) AS total_relatedpostlinks
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_post_views, 0) AS total_post_views,
    COALESCE(cm.total_comments_made, 0) AS total_comments_made,
    COALESCE(cr.total_comments_received, 0) AS total_comments_received,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(ph.total_posthistory, 0) AS total_posthistory,
    COALESCE(plp.total_postlinks, 0) + COALESCE(plr.total_relatedpostlinks, 0) AS total_postlinks,
    (COALESCE(p.total_posts, 0) +
     COALESCE(cm.total_comments_made, 0) +
     COALESCE(vc.total_votes_cast, 0) +
     COALESCE(b.total_badges, 0) +
     COALESCE(ph.total_posthistory, 0) +
     COALESCE(plp.total_postlinks, 0) +
     COALESCE(plr.total_relatedpostlinks, 0)
    ) AS activity_score
FROM users u
LEFT JOIN posts_by_user p ON u.id = p.owneruserid
LEFT JOIN comments_made_by_user cm ON u.id = cm.userid
LEFT JOIN comments_received_by_user cr ON u.id = cr.owneruserid
LEFT JOIN votes_cast_by_user vc ON u.id = vc.userid
LEFT JOIN votes_received_by_user vr ON u.id = vr.owneruserid
LEFT JOIN badges_by_user b ON u.id = b.userid
LEFT JOIN posthistory_by_user ph ON u.id = ph.userid
LEFT JOIN postlinks_by_postid plp ON u.id = plp.owneruserid
LEFT JOIN postlinks_by_relatedpostid plr ON u.id = plr.owneruserid
ORDER BY activity_score DESC
LIMIT 10
