/*
  Analytical query for the LDBC SNB benchmark (sf0003) using Iceberg tables via Trino.
  For each forum we compute:
    • Basic forum info (id, title, creation date)
    • Moderator full name
    • Member counts overall and by gender
    • Number of posts and average post length
    • Total likes on posts
    • Number of comments and average comment length
    • Total likes on comments
  The query follows all supplied join rules and uses only the listed tables/columns.
*/
WITH
  -- Basic forum information (id, title, creation date, moderator id)
  forum_base AS (
    SELECT
      f.id AS forum_id,
      f.title AS forum_title,
      f.creation_date AS forum_creation_date,
      f.moderator_person_id
    FROM forum f
  ),

  -- Member counts per forum, broken down by gender
  forum_members AS (
    SELECT
      fm.forum_id,
      COUNT(DISTINCT fm.person_id) AS member_count,
      SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS male_member_count,
      SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_member_count,
      SUM(CASE WHEN p.gender NOT IN ('male', 'female') OR p.gender IS NULL THEN 1 ELSE 0 END) AS other_gender_member_count
    FROM forum_has_member_person fm
    JOIN person p ON fm.person_id = p.id
    GROUP BY fm.forum_id
  ),

  -- Post statistics per forum
  forum_posts AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(DISTINCT p.id) AS post_count,
      AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
  ),

  -- Likes on posts per forum
  forum_post_likes AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
  ),

  -- Comment statistics per forum (comments belong to posts which belong to a forum)
  forum_comments AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(DISTINCT c.id) AS comment_count,
      AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
  ),

  -- Likes on comments per forum
  forum_comment_likes AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
  )
SELECT
  fb.forum_id,
  fb.forum_title,
  fb.forum_creation_date,
  concat(mod.first_name, ' ', mod.last_name) AS moderator_name,
  COALESCE(fm.member_count, 0)               AS member_count,
  COALESCE(fm.male_member_count, 0)          AS male_member_count,
  COALESCE(fm.female_member_count, 0)        AS female_member_count,
  COALESCE(fm.other_gender_member_count, 0) AS other_gender_member_count,
  COALESCE(fp.post_count, 0)                 AS post_count,
  fp.avg_post_length,
  COALESCE(fpl.post_like_count, 0)           AS post_like_count,
  COALESCE(fc.comment_count, 0)              AS comment_count,
  fc.avg_comment_length,
  COALESCE(fcl.comment_like_count, 0)        AS comment_like_count
FROM forum_base fb
LEFT JOIN person mod ON fb.moderator_person_id = mod.id
LEFT JOIN forum_members fm          ON fb.forum_id = fm.forum_id
LEFT JOIN forum_posts fp            ON fb.forum_id = fp.forum_id
LEFT JOIN forum_post_likes fpl      ON fb.forum_id = fpl.forum_id
LEFT JOIN forum_comments fc         ON fb.forum_id = fc.forum_id
LEFT JOIN forum_comment_likes fcl   ON fb.forum_id = fcl.forum_id
ORDER BY fb.forum_id
