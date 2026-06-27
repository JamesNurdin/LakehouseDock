/*
  Analytical overview of user activity across the Stack Exchange dataset.
  For each user we aggregate:
    • Posts authored and their scores, views, answers, comments, favorites
    • Comments made and comment scores
    • Votes cast (total, up‑votes, down‑votes)
    • Votes received on authored posts (total, up‑votes, down‑votes)
    • Badges earned
    • Post‑history events the user participated in
    • Edits performed as the last editor of a post
    • Tags created via excerpt posts owned by the user
  The result is ordered by reputation (descending) and limited to the top 100 users.
*/
WITH
  user_posts AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS post_count,
      SUM(p.score) AS total_post_score,
      SUM(p.viewcount) AS total_view_count,
      SUM(p.answercount) AS total_answer_count,
      SUM(p.commentcount) AS total_comment_count,
      SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
  ),
  user_comments AS (
    SELECT
      c.userid AS userid,
      COUNT(*) AS comment_count,
      SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
  ),
  user_votes_cast AS (
    SELECT
      v.userid AS userid,
      COUNT(*) AS votes_cast,
      SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
      SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(v.id) AS votes_received,
      SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
      SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_badges AS (
    SELECT
      b.userid AS userid,
      COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
  ),
  user_posthistory AS (
    SELECT
      ph.userid AS userid,
      COUNT(*) AS posthistory_events
    FROM posthistory ph
    GROUP BY ph.userid
  ),
  user_edits AS (
    SELECT
      p.lasteditoruserid AS userid,
      COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
  ),
  user_tags AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(up.total_view_count, 0) AS total_view_count,
  COALESCE(up.total_answer_count, 0) AS total_answer_count,
  COALESCE(up.total_comment_count, 0) AS total_comment_count,
  COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.total_comment_score, 0) AS total_comment_score,
  COALESCE(vc.votes_cast, 0) AS votes_cast,
  COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
  COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
  COALESCE(vr.votes_received, 0) AS votes_received,
  COALESCE(vr.upvotes_received, 0) AS upvotes_received,
  COALESCE(vr.downvotes_received, 0) AS downvotes_received,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(ph.posthistory_events, 0) AS posthistory_events,
  COALESCE(ed.edit_count, 0) AS edit_count,
  COALESCE(tg.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up      ON u.id = up.userid
LEFT JOIN user_comments uc   ON u.id = uc.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges ub     ON u.id = ub.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
LEFT JOIN user_edits ed      ON u.id = ed.userid
LEFT JOIN user_tags tg       ON u.id = tg.userid
ORDER BY u.reputation DESC
LIMIT 100
