WITH
    user_base AS (
        SELECT id,
               reputation,
               creationdate,
               views,
               upvotes,
               downvotes
        FROM users
    ),
    post_agg AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_count,
               SUM(score) AS post_score_sum,
               AVG(score) AS post_score_avg
        FROM posts
        GROUP BY owneruserid
    ),
    comment_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS comment_count,
               SUM(score) AS comment_score_sum,
               AVG(score) AS comment_score_avg
        FROM comments
        GROUP BY userid
    ),
    vote_cast_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS votes_cast,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    vote_received_agg AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS votes_received,
               SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badge_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    tag_agg AS (
        SELECT p.owneruserid AS user_id,
               COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    editor_agg AS (
        SELECT lasteditoruserid AS user_id,
               COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    )
SELECT
    ub.id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(pa.post_count, 0)            AS post_count,
    COALESCE(pa.post_score_sum, 0)        AS post_score_sum,
    COALESCE(pa.post_score_avg, 0)        AS post_score_avg,
    COALESCE(ca.comment_count, 0)         AS comment_count,
    COALESCE(ca.comment_score_sum, 0)    AS comment_score_sum,
    COALESCE(ca.comment_score_avg, 0)    AS comment_score_avg,
    COALESCE(vca.votes_cast, 0)           AS votes_cast,
    COALESCE(vca.upvotes_cast, 0)         AS upvotes_cast,
    COALESCE(vca.downvotes_cast, 0)       AS downvotes_cast,
    COALESCE(vra.votes_received, 0)       AS votes_received,
    COALESCE(vra.upvotes_received, 0)     AS upvotes_received,
    COALESCE(vra.downvotes_received, 0)   AS downvotes_received,
    COALESCE(ba.badge_count, 0)           AS badge_count,
    COALESCE(pha.posthistory_count, 0)    AS posthistory_count,
    COALESCE(ta.tag_count, 0)             AS tag_count,
    COALESCE(ea.edit_count, 0)            AS edit_count,
    -- Derived engagement metric
    (COALESCE(pa.post_count, 0) * 2
     + COALESCE(ca.comment_count, 0)
     + COALESCE(vca.votes_cast, 0)
     + COALESCE(ba.badge_count, 0) * 5)   AS engagement_score
FROM user_base ub
LEFT JOIN post_agg pa          ON pa.user_id = ub.id
LEFT JOIN comment_agg ca       ON ca.user_id = ub.id
LEFT JOIN vote_cast_agg vca    ON vca.user_id = ub.id
LEFT JOIN vote_received_agg vra ON vra.user_id = ub.id
LEFT JOIN badge_agg ba         ON ba.user_id = ub.id
LEFT JOIN posthistory_agg pha  ON pha.user_id = ub.id
LEFT JOIN tag_agg ta           ON ta.user_id = ub.id
LEFT JOIN editor_agg ea        ON ea.user_id = ub.id
ORDER BY engagement_score DESC
LIMIT 100
