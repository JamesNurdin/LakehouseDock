WITH
    post_base AS (
        SELECT
            id,
            posttypeid,
            creationdate,
            score,
            viewcount,
            owneruserid,
            answercount,
            commentcount,
            favoritecount,
            lasteditoruserid
        FROM posts
        WHERE posttypeid = 1  -- restrict to questions (optional analytical filter)
    ),
    comment_stats AS (
        SELECT
            postid,
            COUNT(*) AS comment_cnt,
            SUM(score) AS comment_score_sum,
            AVG(score) AS comment_score_avg
        FROM comments
        GROUP BY postid
    ),
    vote_stats AS (
        SELECT
            postid,
            COUNT(*) AS vote_cnt,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt
        FROM votes
        GROUP BY postid
    ),
    postlink_out_stats AS (
        SELECT
            postid,
            COUNT(*) AS outgoing_link_cnt
        FROM postlinks
        GROUP BY postid
    ),
    postlink_in_stats AS (
        SELECT
            relatedpostid,
            COUNT(*) AS incoming_link_cnt
        FROM postlinks
        GROUP BY relatedpostid
    ),
    tag_stats AS (
        SELECT
            excerptpostid,
            COUNT(*) AS tag_cnt,
            SUM(count) AS tag_use_sum
        FROM tags
        GROUP BY excerptpostid
    )
SELECT
    p.id AS post_id,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount AS post_comment_cnt,
    p.favoritecount,
    COALESCE(c.comment_cnt, 0) AS comment_cnt,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(c.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(v.vote_cnt, 0) AS vote_cnt,
    COALESCE(v.upvote_cnt, 0) AS upvote_cnt,
    COALESCE(v.downvote_cnt, 0) AS downvote_cnt,
    COALESCE(o.outgoing_link_cnt, 0) AS outgoing_link_cnt,
    COALESCE(i.incoming_link_cnt, 0) AS incoming_link_cnt,
    COALESCE(t.tag_cnt, 0) AS tag_cnt,
    COALESCE(t.tag_use_sum, 0) AS tag_use_sum
FROM post_base p
LEFT JOIN comment_stats c ON c.postid = p.id
LEFT JOIN vote_stats v ON v.postid = p.id
LEFT JOIN postlink_out_stats o ON o.postid = p.id
LEFT JOIN postlink_in_stats i ON i.relatedpostid = p.id
LEFT JOIN tag_stats t ON t.excerptpostid = p.id
ORDER BY p.creationdate DESC
LIMIT 100
