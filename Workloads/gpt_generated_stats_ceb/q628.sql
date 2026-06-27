WITH comments_agg AS (
    SELECT postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score
    FROM comments
    GROUP BY postid
),
votes_agg AS (
    SELECT postid,
        COUNT(*) AS vote_cnt
    FROM votes
    GROUP BY postid
),
postlinks_agg AS (
    SELECT postid,
        COUNT(*) AS link_cnt,
        COUNT(DISTINCT relatedpostid) AS distinct_related_cnt
    FROM postlinks
    GROUP BY postid
)
SELECT
    p.posttypeid,
    p.owneruserid,
    COUNT(*) AS total_posts,
    AVG(p.score) AS avg_post_score,
    SUM(COALESCE(ca.comment_cnt, 0)) AS total_comments,
    SUM(COALESCE(ca.comment_score, 0)) AS total_comment_score,
    SUM(COALESCE(va.vote_cnt, 0)) AS total_votes,
    SUM(COALESCE(pl.link_cnt, 0)) AS total_links,
    SUM(COALESCE(pl.distinct_related_cnt, 0)) AS total_distinct_related_posts,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS pct_of_total_posts
FROM posts p
LEFT JOIN comments_agg ca ON ca.postid = p.id
LEFT JOIN votes_agg va ON va.postid = p.id
LEFT JOIN postlinks_agg pl ON pl.postid = p.id
GROUP BY p.posttypeid, p.owneruserid
ORDER BY total_posts DESC
LIMIT 10
