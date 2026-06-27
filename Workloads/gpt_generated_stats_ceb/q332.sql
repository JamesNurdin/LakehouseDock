WITH vote_agg AS (
    SELECT
        v.postid,
        COUNT(*) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes,
        SUM(CASE WHEN v.votetypeid = 3 THEN COALESCE(v.bountyamount, 0) ELSE 0 END) AS total_bounty
    FROM votes v
    GROUP BY v.postid
),

tag_agg AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(*) AS tag_count,
        SUM(t.count) AS tag_total_count
    FROM tags t
    GROUP BY t.excerptpostid
)
SELECT
    p.id,
    p.posttypeid,
    p.creationdate,
    p.score,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(v.total_votes, 0) AS total_votes,
    COALESCE(v.upvotes, 0) AS upvotes,
    COALESCE(v.downvotes, 0) AS downvotes,
    COALESCE(v.total_bounty, 0) AS total_bounty,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(t.tag_total_count, 0) AS tag_total_count,
    (p.score + COALESCE(v.total_votes, 0) + COALESCE(t.tag_count, 0)) AS engagement_score
FROM posts p
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN tag_agg t ON t.post_id = p.id
ORDER BY p.creationdate DESC
LIMIT 100
