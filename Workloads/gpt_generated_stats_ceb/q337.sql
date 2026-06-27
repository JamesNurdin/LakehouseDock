WITH user_posts AS (
   SELECT u.id AS user_id,
          u.reputation,
          u.creationdate,
          COUNT(p.id) AS post_count,
          COALESCE(SUM(p.score), 0) AS total_post_score,
          COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
          COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount,
          COALESCE(SUM(p.answercount), 0) AS total_answercount,
          COALESCE(SUM(p.commentcount), 0) AS total_commentcount
   FROM users u
   LEFT JOIN posts p
     ON p.owneruserid = u.id
   GROUP BY u.id, u.reputation, u.creationdate
),
user_comments AS (
   SELECT u.id AS user_id,
          COUNT(c.id) AS comment_made_count
   FROM users u
   LEFT JOIN comments c
     ON c.userid = u.id
   GROUP BY u.id
),
user_comments_received AS (
   SELECT u.id AS user_id,
          COUNT(c.id) AS comment_received_count
   FROM users u
   JOIN posts p
     ON p.owneruserid = u.id
   LEFT JOIN comments c
     ON c.postid = p.id
   GROUP BY u.id
),
user_votes_given AS (
   SELECT u.id AS user_id,
          COUNT(v.id) AS votes_given_count,
          SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_given,
          SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_given
   FROM users u
   LEFT JOIN votes v
     ON v.userid = u.id
   GROUP BY u.id
),
user_votes_received AS (
   SELECT u.id AS user_id,
          COUNT(v.id) AS votes_received_count,
          SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
          SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
   FROM users u
   JOIN posts p
     ON p.owneruserid = u.id
   LEFT JOIN votes v
     ON v.postid = p.id
   GROUP BY u.id
),
user_badges AS (
   SELECT u.id AS user_id,
          COUNT(b.id) AS badge_count
   FROM users u
   LEFT JOIN badges b
     ON b.userid = u.id
   GROUP BY u.id
),
user_edits AS (
   SELECT u.id AS user_id,
          COUNT(ph.id) AS edit_count
   FROM users u
   LEFT JOIN posthistory ph
     ON ph.userid = u.id
   GROUP BY u.id
),
user_tags AS (
   SELECT u.id AS user_id,
          COUNT(DISTINCT t.id) AS distinct_tag_count
   FROM users u
   JOIN posts p
     ON p.owneruserid = u.id
   JOIN tags t
     ON t.excerptpostid = p.id
   GROUP BY u.id
),
user_outgoing_links AS (
   SELECT u.id AS user_id,
          COUNT(pl.id) AS outgoing_links
   FROM users u
   JOIN posts p
     ON p.owneruserid = u.id
   LEFT JOIN postlinks pl
     ON pl.postid = p.id
   GROUP BY u.id
),
user_incoming_links AS (
   SELECT u.id AS user_id,
          COUNT(pl2.id) AS incoming_links
   FROM users u
   JOIN posts p
     ON p.owneruserid = u.id
   LEFT JOIN postlinks pl2
     ON pl2.relatedpostid = p.id
   GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.creationdate,
       up.post_count,
       up.total_post_score,
       up.total_viewcount,
       up.total_favoritecount,
       up.total_answercount,
       up.total_commentcount,
       uc.comment_made_count,
       ucr.comment_received_count,
       ug.votes_given_count,
       ug.upvotes_given,
       ug.downvotes_given,
       ur.votes_received_count,
       ur.upvotes_received,
       ur.downvotes_received,
       ub.badge_count,
       ue.edit_count,
       ut.distinct_tag_count,
       ul.outgoing_links,
       il.incoming_links
FROM user_posts up
LEFT JOIN user_comments uc
  ON uc.user_id = up.user_id
LEFT JOIN user_comments_received ucr
  ON ucr.user_id = up.user_id
LEFT JOIN user_votes_given ug
  ON ug.user_id = up.user_id
LEFT JOIN user_votes_received ur
  ON ur.user_id = up.user_id
LEFT JOIN user_badges ub
  ON ub.user_id = up.user_id
LEFT JOIN user_edits ue
  ON ue.user_id = up.user_id
LEFT JOIN user_tags ut
  ON ut.user_id = up.user_id
LEFT JOIN user_outgoing_links ul
  ON ul.user_id = up.user_id
LEFT JOIN user_incoming_links il
  ON il.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
