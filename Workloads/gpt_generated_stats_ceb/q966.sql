WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.score,
        p.viewcount,
        p.commentcount,
        p.owneruserid
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),
post_votes AS (
    SELECT
        postid,
        COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
post_comments AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
owner_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
)
SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id) AS total_posts,
    SUM(tp.score) AS total_post_score,
    AVG(tp.viewcount) AS avg_viewcount,
    SUM(tp.commentcount) AS total_post_commentcount,
    COALESCE(SUM(pv.vote_count), 0) AS total_votes,
    COALESCE(SUM(pc.comment_count), 0) AS total_comments,
    COALESCE(SUM(ob.badge_count), 0) AS total_owner_badges,
    AVG(u.reputation) AS avg_owner_reputation
FROM tag_posts tp
LEFT JOIN post_votes pv ON pv.postid = tp.post_id
LEFT JOIN post_comments pc ON pc.postid = tp.post_id
JOIN users u ON u.id = tp.owneruserid
LEFT JOIN owner_badges ob ON ob.userid = u.id
GROUP BY tp.tag_id
ORDER BY total_posts DESC
LIMIT 20
