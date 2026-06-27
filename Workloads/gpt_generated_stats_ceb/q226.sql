/*
  Analytical query: user activity summary
  Tables used: users, posts, comments, votes, badges, posthistory, tags, postlinks
  Join rules respected as per the provided list.
*/
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0)               AS post_count,
    COALESCE(up.total_score, 0)              AS total_post_score,
    COALESCE(up.avg_viewcount, 0)            AS avg_post_viewcount,
    COALESCE(ue.edit_count, 0)               AS edit_count,
    COALESCE(uc.comment_count, 0)            AS comment_count,
    COALESCE(uv.vote_count, 0)               AS vote_count,
    COALESCE(ub.badge_count, 0)              AS badge_count,
    COALESCE(uph.posthistory_count, 0)       AS posthistory_count,
    COALESCE(ut.tag_count, 0)                AS tag_count,
    COALESCE(ul.link_count, 0)               AS link_count
FROM users u
LEFT JOIN (
    SELECT
        owneruserid,
        COUNT(*)                         AS post_count,
        SUM(score)                       AS total_score,
        AVG(viewcount)                   AS avg_viewcount
    FROM posts
    GROUP BY owneruserid
) up ON up.owneruserid = u.id
LEFT JOIN (
    SELECT
        lasteditoruserid,
        COUNT(*)                         AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
) ue ON ue.lasteditoruserid = u.id
LEFT JOIN (
    SELECT
        userid,
        COUNT(*)                         AS comment_count
    FROM comments
    GROUP BY userid
) uc ON uc.userid = u.id
LEFT JOIN (
    SELECT
        userid,
        COUNT(*)                         AS vote_count
    FROM votes
    GROUP BY userid
) uv ON uv.userid = u.id
LEFT JOIN (
    SELECT
        userid,
        COUNT(*)                         AS badge_count
    FROM badges
    GROUP BY userid
) ub ON ub.userid = u.id
LEFT JOIN (
    SELECT
        userid,
        COUNT(*)                         AS posthistory_count
    FROM posthistory
    GROUP BY userid
) uph ON uph.userid = u.id
LEFT JOIN (
    SELECT
        p.owneruserid,
        COUNT(DISTINCT t.id)             AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
) ut ON ut.owneruserid = u.id
LEFT JOIN (
    SELECT
        p.owneruserid,
        COUNT(DISTINCT pl.id)            AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
) ul ON ul.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 100
