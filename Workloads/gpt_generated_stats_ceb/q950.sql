WITH comment_agg AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_total,
        COALESCE(SUM(c.score), 0) AS comment_score_sum,
        COUNT(DISTINCT c.userid) AS distinct_commenters
    FROM comments c
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_total,
        COALESCE(SUM(v.votetypeid), 0) AS vote_type_sum,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount,
        COUNT(DISTINCT v.userid) AS distinct_voters
    FROM votes v
    GROUP BY v.postid
),
tag_agg AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(*) AS tag_total
    FROM tags t
    GROUP BY t.excerptpostid
),
posthistory_agg AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS posthistory_total
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
owner_info AS (
    SELECT
        u.id AS user_id,
        u.reputation AS owner_reputation
    FROM users u
),
editor_info AS (
    SELECT
        u.id AS user_id,
        u.reputation AS editor_reputation
    FROM users u
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid,
    p.lasteditoruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(oi.owner_reputation, 0) AS owner_reputation,
    COALESCE(ei.editor_reputation, 0) AS editor_reputation,
    COALESCE(ca.comment_total, 0) AS comment_total,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ca.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(va.vote_total, 0) AS vote_total,
    COALESCE(va.vote_type_sum, 0) AS vote_type_sum,
    COALESCE(va.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(va.distinct_voters, 0) AS distinct_voters,
    COALESCE(phag.posthistory_total, 0) AS posthistory_total,
    COALESCE(tagag.tag_total, 0) AS tag_total,
    CASE
        WHEN COALESCE(va.vote_total, 0) = 0 THEN NULL
        ELSE CAST(COALESCE(ca.comment_total, 0) AS double) / CAST(va.vote_total AS double)
    END AS comments_per_vote
FROM posts p
LEFT JOIN comment_agg ca ON ca.post_id = p.id
LEFT JOIN vote_agg va ON va.post_id = p.id
LEFT JOIN tag_agg tagag ON tagag.post_id = p.id
LEFT JOIN posthistory_agg phag ON phag.post_id = p.id
LEFT JOIN owner_info oi ON oi.user_id = p.owneruserid
LEFT JOIN editor_info ei ON ei.user_id = p.lasteditoruserid
WHERE p.creationdate >= TIMESTAMP '2023-01-01 00:00:00'
  AND p.creationdate < TIMESTAMP '2024-01-01 00:00:00'
ORDER BY p.viewcount DESC
LIMIT 100
