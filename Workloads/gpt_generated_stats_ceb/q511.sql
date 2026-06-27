WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.owneruserid,
        p.score AS post_score,
        u.id AS owner_user_id
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON p.owneruserid = u.id
),
post_comments AS (
    SELECT
        c.postid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.postid
),
post_votes AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    GROUP BY v.postid
),
owner_badges AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
)
SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id) AS num_posts,
    AVG(tp.post_score) AS avg_post_score,
    COALESCE(SUM(pc.comment_count), 0) AS total_comments,
    COALESCE(SUM(pv.vote_count), 0) AS total_votes,
    COALESCE(SUM(pv.upvote_count), 0) AS total_upvotes,
    COALESCE(SUM(pv.downvote_count), 0) AS total_downvotes,
    COUNT(DISTINCT tp.owner_user_id) AS distinct_owners,
    COALESCE(SUM(ob.badge_count), 0) AS total_owner_badges
FROM tag_posts tp
LEFT JOIN post_comments pc ON tp.post_id = pc.postid
LEFT JOIN post_votes pv ON tp.post_id = pv.postid
LEFT JOIN owner_badges ob ON tp.owner_user_id = ob.userid
GROUP BY tp.tag_id
ORDER BY total_votes DESC
LIMIT 10
