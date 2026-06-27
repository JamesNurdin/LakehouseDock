WITH comment_stats AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY postid
),
vote_stats AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt
    FROM votes
    GROUP BY postid
),
tag_stats AS (
    SELECT
        excerptpostid AS postid,
        COUNT(*) AS tag_cnt
    FROM tags
    GROUP BY excerptpostid
),
owner_info AS (
    SELECT
        u.id AS user_id,
        u.reputation AS reputation,
        u.creationdate AS user_creationdate
    FROM users u
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    COALESCE(cs.comment_cnt, 0) AS comment_count,
    COALESCE(cs.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(vs.vote_cnt, 0) AS vote_count,
    COALESCE(vs.upvote_cnt, 0) AS upvote_count,
    COALESCE(vs.downvote_cnt, 0) AS downvote_count,
    COALESCE(ts.tag_cnt, 0) AS tag_count,
    COALESCE(oi_owner.reputation, 0) AS owner_reputation,
    COALESCE(oi_editor.reputation, 0) AS last_editor_reputation,
    (p.viewcount + COALESCE(vs.vote_cnt, 0) + COALESCE(cs.comment_cnt, 0) + COALESCE(p.answercount, 0) + COALESCE(ts.tag_cnt, 0)) AS engagement_score
FROM posts p
LEFT JOIN comment_stats cs ON cs.postid = p.id
LEFT JOIN vote_stats vs ON vs.postid = p.id
LEFT JOIN tag_stats ts ON ts.postid = p.id
LEFT JOIN owner_info oi_owner ON oi_owner.user_id = p.owneruserid
LEFT JOIN owner_info oi_editor ON oi_editor.user_id = p.lasteditoruserid
ORDER BY engagement_score DESC
LIMIT 10
