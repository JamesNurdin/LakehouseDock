WITH
  user_posts AS (
    SELECT
      u.id AS user_id,
      u.reputation,
      COUNT(p.id) AS total_posts,
      SUM(p.score) AS total_post_score,
      SUM(p.answercount) AS total_answers,
      MAX(p.creationdate) AS last_post_date
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
  ),
  user_comments AS (
    SELECT
      u.id AS user_id,
      COUNT(c.id) AS total_comments,
      SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
      ON c.userid = u.id
    GROUP BY u.id
  ),
  user_votes_cast AS (
    SELECT
      u.id AS user_id,
      COUNT(v.id) AS total_votes_cast
    FROM users u
    LEFT JOIN votes v
      ON v.userid = u.id
    GROUP BY u.id
  ),
  user_votes_received AS (
    SELECT
      u.id AS user_id,
      COUNT(v.id) AS total_votes_received
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN votes v
      ON v.postid = p.id
    GROUP BY u.id
  ),
  user_badges AS (
    SELECT
      u.id AS user_id,
      COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b
      ON b.userid = u.id
    GROUP BY u.id
  ),
  user_tags AS (
    SELECT
      u.id AS user_id,
      COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN tags t
      ON t.excerptpostid = p.id
    GROUP BY u.id
  ),
  user_post_links AS (
    SELECT
      u.id AS user_id,
      COUNT(pl.id) AS total_post_links
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
      ON pl.postid = p.id
    GROUP BY u.id
  ),
  user_related_links AS (
    SELECT
      u.id AS user_id,
      COUNT(pl.id) AS total_related_links
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
      ON pl.relatedpostid = p.id
    GROUP BY u.id
  ),
  user_edits AS (
    SELECT
      u.id AS user_id,
      COUNT(ph.id) AS total_edits
    FROM users u
    LEFT JOIN posthistory ph
      ON ph.userid = u.id
    GROUP BY u.id
  )
SELECT
  up.user_id,
  up.reputation,
  up.total_posts,
  up.total_post_score,
  up.total_answers,
  up.last_post_date,
  uc.total_comments,
  uc.total_comment_score,
  uv_cast.total_votes_cast,
  uv_received.total_votes_received,
  ub.total_badges,
  ut.distinct_tag_count,
  upl.total_post_links,
  url.total_related_links,
  ue.total_edits,
  ROW_NUMBER() OVER (ORDER BY up.total_posts DESC) AS user_rank
FROM user_posts up
LEFT JOIN user_comments uc
  ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast
  ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_received
  ON uv_received.user_id = up.user_id
LEFT JOIN user_badges ub
  ON ub.user_id = up.user_id
LEFT JOIN user_tags ut
  ON ut.user_id = up.user_id
LEFT JOIN user_post_links upl
  ON upl.user_id = up.user_id
LEFT JOIN user_related_links url
  ON url.user_id = up.user_id
LEFT JOIN user_edits ue
  ON ue.user_id = up.user_id
ORDER BY up.total_posts DESC
LIMIT 100
