WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS post_score_sum,
           COALESCE(SUM(p.viewcount), 0) AS post_view_sum,
           CASE WHEN COUNT(p.id) = 0 THEN 0 ELSE AVG(p.score) END AS post_score_avg
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS edit_count
    FROM users u
    LEFT JOIN posts p
      ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c
      ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM users u
    LEFT JOIN votes v
      ON v.userid = u.id
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
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
      ON ph.userid = u.id
    GROUP BY u.id
),
user_tag_excerpts AS (
    SELECT u.id AS user_id,
           COUNT(t.id) AS tag_excerpts_owned
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN tags t
      ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks_owned AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS postlink_owned_count
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
      ON pl.postid = p.id
    GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       up.post_count,
       up.post_score_sum,
       up.post_view_sum,
       up.post_score_avg,
       ue.edit_count,
       uc.comment_count,
       uc.comment_score_sum,
       uv.vote_count,
       uv.upvote_count,
       uv.downvote_count,
       ub.badge_count,
       uph.posthistory_count,
       ut.tag_excerpts_owned,
       upl.postlink_owned_count
FROM users u
LEFT JOIN user_posts up
  ON up.user_id = u.id
LEFT JOIN user_edits ue
  ON ue.user_id = u.id
LEFT JOIN user_comments uc
  ON uc.user_id = u.id
LEFT JOIN user_votes uv
  ON uv.user_id = u.id
LEFT JOIN user_badges ub
  ON ub.user_id = u.id
LEFT JOIN user_posthistory uph
  ON uph.user_id = u.id
LEFT JOIN user_tag_excerpts ut
  ON ut.user_id = u.id
LEFT JOIN user_postlinks_owned upl
  ON upl.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
