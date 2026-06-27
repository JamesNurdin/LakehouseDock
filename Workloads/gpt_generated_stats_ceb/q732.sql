WITH post_votes AS (
   SELECT
       p.id AS post_id,
       p.posttypeid,
       p.creationdate,
       p.score,
       p.viewcount,
       p.owneruserid,
       p.answercount,
       p.commentcount,
       p.favoritecount,
       COUNT(v.id) AS vote_count,
       SUM(CASE WHEN v.votetypeid = 3 THEN v.bountyamount ELSE 0 END) AS total_bounty_amount
   FROM posts p
   LEFT JOIN votes v ON v.postid = p.id
   GROUP BY
       p.id,
       p.posttypeid,
       p.creationdate,
       p.score,
       p.viewcount,
       p.owneruserid,
       p.answercount,
       p.commentcount,
       p.favoritecount
),
post_tags AS (
   SELECT
       p.id AS post_id,
       COUNT(t.id) AS tag_count
   FROM posts p
   LEFT JOIN tags t ON t.excerptpostid = p.id
   GROUP BY p.id
)
SELECT
   pv.post_id,
   pv.posttypeid,
   pv.creationdate,
   pv.score,
   pv.viewcount,
   pv.owneruserid,
   pv.answercount,
   pv.commentcount,
   pv.favoritecount,
   pv.vote_count,
   pv.total_bounty_amount,
   pt.tag_count,
   ROW_NUMBER() OVER (ORDER BY pv.score DESC) AS rank_by_score
FROM post_votes pv
LEFT JOIN post_tags pt ON pt.post_id = pv.post_id
ORDER BY pv.score DESC
LIMIT 10
