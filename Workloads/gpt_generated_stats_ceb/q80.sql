WITH comment_agg AS (
    SELECT
        c.postid AS postid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        COUNT(DISTINCT c.userid) AS distinct_comment_user_count
    FROM comments c
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid AS postid,
        COUNT(*) AS vote_count,
        SUM(v.votetypeid) AS vote_type_sum,
        COUNT(DISTINCT v.userid) AS distinct_vote_user_count
    FROM votes v
    GROUP BY v.postid
)
SELECT
    p.id AS post_id,
    p.creationdate AS post_creationdate,
    p.score AS post_score,
    p.viewcount AS post_viewcount,
    p.owneruserid AS post_owner_user_id,
    u_owner.reputation AS owner_reputation,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(va.vote_type_sum, 0) AS vote_type_sum,
    (p.score + COALESCE(ca.comment_score_sum, 0) + COALESCE(va.vote_count, 0) * 2) AS engagement_score,
    ROW_NUMBER() OVER (ORDER BY (p.score + COALESCE(ca.comment_score_sum, 0) + COALESCE(va.vote_count, 0) * 2) DESC) AS post_rank
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN vote_agg va ON va.postid = p.id
LEFT JOIN users u_owner ON u_owner.id = p.owneruserid
WHERE p.posttypeid = 1
ORDER BY engagement_score DESC
LIMIT 10
