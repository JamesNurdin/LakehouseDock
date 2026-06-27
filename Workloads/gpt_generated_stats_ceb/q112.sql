WITH comment_agg AS (
    SELECT postid,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT postid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY postid
),
outgoing_link_agg AS (
    SELECT postid,
           COUNT(*) AS outgoing_links
    FROM postlinks
    GROUP BY postid
),
incoming_link_agg AS (
    SELECT relatedpostid,
           COUNT(*) AS incoming_links
    FROM postlinks
    GROUP BY relatedpostid
),
tag_agg AS (
    SELECT excerptpostid,
           COUNT(*) AS tag_excerpt_count
    FROM tags
    GROUP BY excerptpostid
),
history_agg AS (
    SELECT posthistorytypeid,
           COUNT(*) AS history_count
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT p.id,
       p.posttypeid,
       p.creationdate,
       p.score AS post_score,
       p.viewcount,
       p.owneruserid,
       p.answercount,
       p.commentcount,
       p.favoritecount,
       p.lasteditoruserid,
       COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(va.vote_count, 0) AS vote_count,
       COALESCE(va.upvote_count, 0) AS upvote_count,
       COALESCE(va.downvote_count, 0) AS downvote_count,
       COALESCE(ola.outgoing_links, 0) AS outgoing_links,
       COALESCE(ila.incoming_links, 0) AS incoming_links,
       COALESCE(ta.tag_excerpt_count, 0) AS tag_excerpt_count,
       COALESCE(ha.history_count, 0) AS history_count,
       CASE WHEN p.viewcount > 0 THEN p.score / p.viewcount ELSE NULL END AS post_score_per_view
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN vote_agg va ON va.postid = p.id
LEFT JOIN outgoing_link_agg ola ON ola.postid = p.id
LEFT JOIN incoming_link_agg ila ON ila.relatedpostid = p.id
LEFT JOIN tag_agg ta ON ta.excerptpostid = p.id
LEFT JOIN history_agg ha ON ha.posthistorytypeid = p.id
WHERE p.posttypeid = 1
ORDER BY comment_score_sum DESC
LIMIT 50
