WITH post_comments AS (
    SELECT postid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY postid
),
post_votes AS (
    SELECT postid, COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
user_badges AS (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_links AS (
    SELECT post_id, COUNT(*) AS link_count
    FROM (
        SELECT postid AS post_id FROM postlinks
        UNION ALL
        SELECT relatedpostid AS post_id FROM postlinks
    ) pl
    GROUP BY post_id
),
post_tags AS (
    SELECT excerptpostid AS post_id, COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    u.id AS owner_user_id,
    u.reputation,
    COALESCE(pc.comment_count, 0) AS comment_count,
    COALESCE(pv.vote_count, 0) AS vote_count,
    COALESCE(ub.badge_count, 0) AS owner_badge_count,
    COALESCE(pl.link_count, 0) AS linked_post_count,
    COALESCE(pt.tag_count, 0) AS tag_count,
    (p.score * 2
     + COALESCE(pc.comment_count, 0)
     + COALESCE(pv.vote_count, 0)
     + COALESCE(ub.badge_count, 0) * 3
     + COALESCE(pl.link_count, 0) * 2
     + COALESCE(pt.tag_count, 0) * 1) AS engagement_score
FROM posts p
JOIN users u ON u.id = p.owneruserid
LEFT JOIN post_comments pc ON pc.postid = p.id
LEFT JOIN post_votes pv ON pv.postid = p.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN post_links pl ON pl.post_id = p.id
LEFT JOIN post_tags pt ON pt.post_id = p.id
WHERE p.posttypeid = 1
ORDER BY engagement_score DESC
LIMIT 10
