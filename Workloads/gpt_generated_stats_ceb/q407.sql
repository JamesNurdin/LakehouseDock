WITH comment_counts AS (
    SELECT postid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY postid
),
vote_counts AS (
    SELECT postid,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY postid
)
SELECT
    p.id AS post_id,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid AS owner_user_id,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vc.upvote_count, 0) AS upvote_count,
    COALESCE(vc.downvote_count, 0) AS downvote_count,
    CASE WHEN p.lasteditoruserid IS NOT NULL THEN 1 ELSE 0 END AS edited_flag,
    (COALESCE(cc.comment_count, 0) + COALESCE(vc.upvote_count, 0) - COALESCE(vc.downvote_count, 0) +
     CASE WHEN p.lasteditoruserid IS NOT NULL THEN 2 ELSE 0 END) AS activity_score
FROM posts p
LEFT JOIN comment_counts cc ON cc.postid = p.id
LEFT JOIN vote_counts vc ON vc.postid = p.id
ORDER BY activity_score DESC
LIMIT 20
