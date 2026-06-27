WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        COUNT(CASE WHEN votetypeid = 1 THEN 1 END) AS upvote_cnt,
        COUNT(CASE WHEN votetypeid = 2 THEN 1 END) AS downvote_cnt
    FROM votes
    GROUP BY postid
),
outgoing_link_agg AS (
    SELECT
        postid,
        COUNT(*) AS outgoing_link_cnt
    FROM postlinks
    GROUP BY postid
),
incoming_link_agg AS (
    SELECT
        relatedpostid AS postid,
        COUNT(*) AS incoming_link_cnt
    FROM postlinks
    GROUP BY relatedpostid
),
tag_agg AS (
    SELECT
        excerptpostid AS postid,
        COUNT(*) AS tag_cnt
    FROM tags
    GROUP BY excerptpostid
)
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
    COALESCE(ca.comment_cnt, 0) AS comment_cnt,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_cnt, 0) AS vote_cnt,
    COALESCE(va.upvote_cnt, 0) AS upvote_cnt,
    COALESCE(va.downvote_cnt, 0) AS downvote_cnt,
    COALESCE(ol.outgoing_link_cnt, 0) AS outgoing_link_cnt,
    COALESCE(il.incoming_link_cnt, 0) AS incoming_link_cnt,
    COALESCE(ta.tag_cnt, 0) AS tag_cnt
FROM posts AS p
LEFT JOIN comment_agg AS ca ON ca.postid = p.id
LEFT JOIN vote_agg AS va ON va.postid = p.id
LEFT JOIN outgoing_link_agg AS ol ON ol.postid = p.id
LEFT JOIN incoming_link_agg AS il ON il.postid = p.id
LEFT JOIN tag_agg AS ta ON ta.postid = p.id
ORDER BY p.score DESC
LIMIT 100
