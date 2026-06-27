WITH comment_agg AS (
  SELECT postid,
         COUNT(*) AS comment_cnt,
         SUM(score) AS comment_score_sum
  FROM comments
  GROUP BY postid
),
vote_agg AS (
  SELECT postid,
         COUNT(*) AS vote_cnt,
         SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
         SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt
  FROM votes
  GROUP BY postid
),
posthistory_agg AS (
  SELECT posthistorytypeid,
         COUNT(*) AS history_cnt
  FROM posthistory
  GROUP BY posthistorytypeid
),
postlink_src_agg AS (
  SELECT postid,
         COUNT(*) AS link_src_cnt
  FROM postlinks
  GROUP BY postid
),
postlink_tgt_agg AS (
  SELECT relatedpostid,
         COUNT(*) AS link_tgt_cnt
  FROM postlinks
  GROUP BY relatedpostid
),
tag_agg AS (
  SELECT excerptpostid,
         COUNT(*) AS tag_cnt
  FROM tags
  GROUP BY excerptpostid
),
badge_agg AS (
  SELECT userid,
         COUNT(*) AS badge_cnt
  FROM badges
  GROUP BY userid
)
SELECT
  p.id AS post_id,
  p.posttypeid,
  p.creationdate,
  p.score AS post_score,
  p.viewcount,
  p.answercount,
  p.commentcount AS post_comment_count,
  p.favoritecount,
  p.owneruserid AS owner_user_id,
  u.reputation AS owner_reputation,
  COALESCE(c.comment_cnt, 0) AS comment_count,
  COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
  COALESCE(v.vote_cnt, 0) AS vote_count,
  COALESCE(v.upvote_cnt, 0) AS upvote_count,
  COALESCE(v.downvote_cnt, 0) AS downvote_count,
  COALESCE(ph.history_cnt, 0) AS post_history_count,
  COALESCE(pls.link_src_cnt, 0) AS outgoing_link_count,
  COALESCE(plt.link_tgt_cnt, 0) AS incoming_link_count,
  COALESCE(t.tag_cnt, 0) AS tag_excerpt_count,
  COALESCE(b.badge_cnt, 0) AS owner_badge_count
FROM posts p
LEFT JOIN users u ON p.owneruserid = u.id
LEFT JOIN comment_agg c ON c.postid = p.id
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN posthistory_agg ph ON ph.posthistorytypeid = p.id
LEFT JOIN postlink_src_agg pls ON pls.postid = p.id
LEFT JOIN postlink_tgt_agg plt ON plt.relatedpostid = p.id
LEFT JOIN tag_agg t ON t.excerptpostid = p.id
LEFT JOIN badge_agg b ON b.userid = u.id
ORDER BY p.creationdate DESC
LIMIT 100
