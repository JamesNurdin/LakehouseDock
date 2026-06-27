WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        COUNT(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        COUNT(DISTINCT userid) AS distinct_voters
    FROM votes
    GROUP BY postid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS posthistory_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    p.posttypeid,
    COUNT(*) AS total_posts,
    COALESCE(SUM(p.score), 0) AS total_score,
    COALESCE(AVG(p.score), 0) AS avg_score,
    COALESCE(SUM(p.viewcount), 0) AS total_views,
    COALESCE(AVG(p.viewcount), 0) AS avg_views,
    COALESCE(SUM(p.answercount), 0) AS total_answers,
    COALESCE(AVG(p.answercount), 0) AS avg_answers,
    COALESCE(SUM(p.commentcount), 0) AS total_comments,
    COALESCE(AVG(p.commentcount), 0) AS avg_comments,
    COALESCE(SUM(COALESCE(ca.comment_cnt, 0)), 0) AS total_comment_rows,
    COALESCE(SUM(COALESCE(ca.distinct_commenters, 0)), 0) AS total_distinct_commenters,
    COALESCE(SUM(COALESCE(va.vote_cnt, 0)), 0) AS total_votes,
    COALESCE(SUM(COALESCE(va.distinct_voters, 0)), 0) AS total_distinct_voters,
    COALESCE(SUM(COALESCE(pha.posthistory_cnt, 0)), 0) AS total_posthistory_entries
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN vote_agg va ON va.postid = p.id
LEFT JOIN posthistory_agg pha ON pha.postid = p.id
GROUP BY p.posttypeid
ORDER BY total_score DESC
