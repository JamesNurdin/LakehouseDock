WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(CASE WHEN bountyamount IS NOT NULL THEN bountyamount ELSE 0 END) AS total_bounty_amount
    FROM votes
    GROUP BY postid
),
history_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
tag_agg AS (
    SELECT
        excerptpostid AS postid,
        COUNT(*) AS tag_excerpt_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT
    p.id AS post_id,
    p.creationdate AS post_creationdate,
    p.posttypeid AS post_type,
    p.score AS post_score,
    p.viewcount AS post_viewcount,
    u.id AS owner_user_id,
    u.reputation AS owner_reputation,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(va.upvote_count, 0) AS upvote_count,
    COALESCE(va.downvote_count, 0) AS downvote_count,
    COALESCE(va.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(ha.posthistory_count, 0) AS posthistory_count,
    COALESCE(ta.tag_excerpt_count, 0) AS tag_excerpt_count,
    (COALESCE(ca.comment_count, 0) + COALESCE(va.vote_count, 0) + COALESCE(ha.posthistory_count, 0)) AS total_engagement,
    CASE
        WHEN (COALESCE(va.upvote_count, 0) + COALESCE(va.downvote_count, 0)) > 0
        THEN COALESCE(va.upvote_count, 0) * 1.0 / (COALESCE(va.upvote_count, 0) + COALESCE(va.downvote_count, 0))
        ELSE NULL
    END AS upvote_ratio
FROM posts p
LEFT JOIN users u
    ON p.owneruserid = u.id
LEFT JOIN comment_agg ca
    ON ca.postid = p.id
LEFT JOIN vote_agg va
    ON va.postid = p.id
LEFT JOIN history_agg ha
    ON ha.postid = p.id
LEFT JOIN tag_agg ta
    ON ta.postid = p.id
ORDER BY total_engagement DESC
LIMIT 10
