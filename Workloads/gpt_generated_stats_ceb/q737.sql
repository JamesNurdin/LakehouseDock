WITH tag_aggregates AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_usage_count,
        COUNT(DISTINCT p.id) AS post_cnt,
        AVG(p.score) AS avg_post_score,
        SUM(v.total_votes) AS total_votes,
        SUM(c.total_comments) AS total_comments,
        SUM(b.total_badges) AS total_owner_badges,
        AVG(u.reputation) AS avg_owner_reputation
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON p.owneruserid = u.id
    LEFT JOIN (
        SELECT postid, COUNT(*) AS total_votes
        FROM votes
        GROUP BY postid
    ) v ON v.postid = p.id
    LEFT JOIN (
        SELECT postid, COUNT(*) AS total_comments
        FROM comments
        GROUP BY postid
    ) c ON c.postid = p.id
    LEFT JOIN (
        SELECT userid, COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ) b ON b.userid = u.id
    GROUP BY t.id, t.count
)
SELECT
    tag_id,
    tag_usage_count,
    post_cnt,
    avg_post_score,
    total_votes,
    total_comments,
    total_owner_badges,
    avg_owner_reputation,
    ROW_NUMBER() OVER (ORDER BY total_votes DESC) AS vote_rank
FROM tag_aggregates
ORDER BY total_votes DESC
