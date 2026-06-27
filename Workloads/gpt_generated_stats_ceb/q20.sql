WITH comment_agg AS (
  SELECT
    postid,
    COUNT(*) AS comment_cnt,
    SUM(score) AS comment_score_sum,
    AVG(score) AS comment_score_avg
  FROM comments
  GROUP BY postid
),
posthistory_agg AS (
  SELECT
    posthistorytypeid AS post_id,
    COUNT(*) AS posthistory_cnt
  FROM posthistory
  GROUP BY posthistorytypeid
),
outgoing_links_agg AS (
  SELECT
    postid AS post_id,
    COUNT(*) AS outgoing_link_cnt
  FROM postlinks
  GROUP BY postid
),
incoming_links_agg AS (
  SELECT
    relatedpostid AS post_id,
    COUNT(*) AS incoming_link_cnt
  FROM postlinks
  GROUP BY relatedpostid
),
tag_agg AS (
  SELECT
    excerptpostid AS post_id,
    COUNT(*) AS tag_excerpt_cnt
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
  p.lasteditoruserid,
  COALESCE(ca.comment_cnt, 0) AS comment_cnt,
  COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
  COALESCE(ca.comment_score_avg, 0) AS comment_score_avg,
  COALESCE(pha.posthistory_cnt, 0) AS posthistory_cnt,
  COALESCE(ola.outgoing_link_cnt, 0) AS outgoing_link_cnt,
  COALESCE(ila.incoming_link_cnt, 0) AS incoming_link_cnt,
  COALESCE(ta.tag_excerpt_cnt, 0) AS tag_excerpt_cnt,
  DENSE_RANK() OVER (ORDER BY COALESCE(ca.comment_cnt, 0) DESC) AS comment_rank
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN posthistory_agg pha ON pha.post_id = p.id
LEFT JOIN outgoing_links_agg ola ON ola.post_id = p.id
LEFT JOIN incoming_links_agg ila ON ila.post_id = p.id
LEFT JOIN tag_agg ta ON ta.post_id = p.id
WHERE p.posttypeid = 1
ORDER BY p.creationdate DESC
LIMIT 200
