WITH
    post_base AS (
        SELECT
            id,
            posttypeid,
            creationdate,
            score,
            answercount
        FROM posts
    ),
    comment_counts AS (
        SELECT
            postid,
            COUNT(*) AS comment_cnt
        FROM comments
        GROUP BY postid
    ),
    vote_counts AS (
        SELECT
            postid,
            COUNT(*) AS vote_cnt
        FROM votes
        GROUP BY postid
    ),
    link_counts AS (
        SELECT
            postid,
            COUNT(*) AS link_cnt
        FROM postlinks
        GROUP BY postid
    ),
    tag_counts AS (
        SELECT
            excerptpostid AS postid,
            COUNT(*) AS tag_cnt
        FROM tags
        GROUP BY excerptpostid
    )
SELECT
    date_trunc('month', pb.creationdate) AS month,
    pb.posttypeid,
    COUNT(pb.id) AS total_posts,
    AVG(pb.score) AS avg_score,
    SUM(pb.answercount) AS total_answers,
    SUM(COALESCE(cc.comment_cnt, 0)) AS total_comments,
    SUM(COALESCE(vc.vote_cnt, 0)) AS total_votes,
    SUM(COALESCE(lc.link_cnt, 0)) AS total_links,
    SUM(COALESCE(tc.tag_cnt, 0)) AS total_tags
FROM post_base pb
LEFT JOIN comment_counts cc ON cc.postid = pb.id
LEFT JOIN vote_counts vc ON vc.postid = pb.id
LEFT JOIN link_counts lc ON lc.postid = pb.id
LEFT JOIN tag_counts tc ON tc.postid = pb.id
GROUP BY date_trunc('month', pb.creationdate), pb.posttypeid
ORDER BY month DESC, pb.posttypeid
