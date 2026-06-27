/*
  Analytical query: enrich each post with comment, vote, and tag aggregates.
  Uses only the selected tables (comments, posts, tags, votes) and the allowed join keys.
*/
WITH post_agg AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid
    FROM posts p
),
comment_agg AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        MAX(c.creationdate) AS last_comment_date
    FROM comments c
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(v.bountyamount) AS total_bounty_amount
    FROM votes v
    GROUP BY v.postid
),
tag_agg AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(*) AS tag_count
    FROM tags t
    GROUP BY t.excerptpostid
)
SELECT
    p.post_id,
    p.posttypeid,
    p.post_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(c.last_comment_date, p.creationdate) AS last_activity_date
FROM post_agg p
LEFT JOIN comment_agg c ON c.post_id = p.post_id
LEFT JOIN vote_agg v ON v.post_id = p.post_id
LEFT JOIN tag_agg t ON t.post_id = p.post_id
WHERE p.post_score >= 10
ORDER BY vote_count DESC, post_score DESC
LIMIT 20
