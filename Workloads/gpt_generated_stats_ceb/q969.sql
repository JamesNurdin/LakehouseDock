WITH user_posts AS (
      SELECT owneruserid AS user_id,
             COUNT(*) AS post_count,
             SUM(score) AS total_post_score,
             AVG(score) AS avg_post_score
      FROM posts
      GROUP BY owneruserid
    ),
    user_comments AS (
      SELECT userid AS user_id,
             COUNT(*) AS comment_count,
             SUM(score) AS total_comment_score
      FROM comments
      GROUP BY userid
    ),
    user_votes AS (
      SELECT userid AS user_id,
             COUNT(*) AS vote_count
      FROM votes
      GROUP BY userid
    ),
    user_badges AS (
      SELECT userid AS user_id,
             COUNT(*) AS badge_count
      FROM badges
      GROUP BY userid
    ),
    user_tag_excerpts AS (
      SELECT p.owneruserid AS user_id,
             COUNT(*) AS tag_excerpt_count
      FROM tags t
      JOIN posts p ON t.excerptpostid = p.id
      GROUP BY p.owneruserid
    ),
    user_postlinks AS (
      SELECT p.owneruserid AS user_id,
             COUNT(*) AS postlink_count
      FROM postlinks pl
      JOIN posts p ON pl.postid = p.id
      GROUP BY p.owneruserid
    ),
    user_posthistory AS (
      SELECT userid AS user_id,
             COUNT(*) AS posthistory_count
      FROM posthistory
      GROUP BY userid
    )
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(up.post_count, 0)               AS post_count,
       COALESCE(up.total_post_score, 0)         AS total_post_score,
       COALESCE(up.avg_post_score, 0)           AS avg_post_score,
       COALESCE(uc.comment_count, 0)            AS comment_count,
       COALESCE(uc.total_comment_score, 0)     AS total_comment_score,
       COALESCE(uv.vote_count, 0)               AS votes_cast,
       COALESCE(ub.badge_count, 0)              AS badge_count,
       COALESCE(ut.tag_excerpt_count, 0)        AS tag_excerpt_count,
       COALESCE(ul.postlink_count, 0)           AS postlink_count,
       COALESCE(uph.posthistory_count, 0)      AS posthistory_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc      ON uc.user_id = u.id
LEFT JOIN user_votes uv         ON uv.user_id = u.id
LEFT JOIN user_badges ub        ON ub.user_id = u.id
LEFT JOIN user_tag_excerpts ut  ON ut.user_id = u.id
LEFT JOIN user_postlinks ul     ON ul.user_id = u.id
LEFT JOIN user_posthistory uph  ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
