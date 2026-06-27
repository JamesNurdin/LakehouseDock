WITH user_posts AS (
  SELECT owneruserid,
         COUNT(*) AS post_count,
         SUM(score) AS total_post_score,
         SUM(viewcount) AS total_view_count,
         SUM(answercount) AS total_answer_count,
         SUM(commentcount) AS total_comment_count,
         SUM(favoritecount) AS total_favorite_count
  FROM posts
  GROUP BY owneruserid
),
user_comments AS (
  SELECT userid,
         COUNT(*) AS comment_count,
         SUM(score) AS total_comment_score
  FROM comments
  GROUP BY userid
),
user_votes_cast AS (
  SELECT userid,
         COUNT(*) AS votes_cast,
         SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
  FROM votes
  GROUP BY userid
),
user_votes_received AS (
  SELECT p.owneruserid,
         COUNT(v.id) AS votes_received,
         SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
  FROM votes v
  JOIN posts p ON v.postid = p.id
  GROUP BY p.owneruserid
),
user_badges AS (
  SELECT userid,
         COUNT(*) AS badge_count
  FROM badges
  GROUP BY userid
),
user_posthistory AS (
  SELECT userid,
         COUNT(*) AS posthistory_events
  FROM posthistory
  GROUP BY userid
),
user_tags AS (
  SELECT p.owneruserid,
         COUNT(t.id) AS tag_excerpts
  FROM tags t
  JOIN posts p ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
user_postlinks_outgoing AS (
  SELECT p.owneruserid,
         COUNT(pl.id) AS outgoing_links
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
),
user_postlinks_incoming AS (
  SELECT p.owneruserid,
         COUNT(pl.id) AS incoming_links
  FROM postlinks pl
  JOIN posts p ON pl.relatedpostid = p.id
  GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_view_count, 0) AS total_view_count,
       COALESCE(up.total_answer_count, 0) AS total_answer_count,
       COALESCE(up.total_comment_count, 0) AS total_comment_count,
       COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uph.posthistory_events, 0) AS posthistory_events,
       COALESCE(ut.tag_excerpts, 0) AS tag_excerpts,
       COALESCE(uplo.outgoing_links, 0) AS outgoing_links,
       COALESCE(upli.incoming_links, 0) AS incoming_links
FROM users u
LEFT JOIN user_posts up ON u.id = up.owneruserid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.owneruserid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_tags ut ON u.id = ut.owneruserid
LEFT JOIN user_postlinks_outgoing uplo ON u.id = uplo.owneruserid
LEFT JOIN user_postlinks_incoming upli ON u.id = upli.owneruserid
ORDER BY u.reputation DESC
LIMIT 100
