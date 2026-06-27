WITH
  -- Post metrics per forum
  post_metrics AS (
    SELECT
      f.id AS forum_id,
      COUNT(p.id) AS post_count,
      AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
  ),

  -- Comment metrics per forum (comments are attached to posts)
  comment_metrics AS (
    SELECT
      f.id AS forum_id,
      COUNT(c.id) AS comment_count,
      AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
  ),

  -- Distinct member count per forum
  member_metrics AS (
    SELECT
      f.id AS forum_id,
      COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
  ),

  -- Tag usage coming from posts
  post_tag_usage AS (
    SELECT
      f.id AS forum_id,
      t.id AS tag_id,
      COUNT(*) AS usage_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON t.id = pht.tag_id
    GROUP BY f.id, t.id
  ),

  -- Tag usage coming from comments
  comment_tag_usage AS (
    SELECT
      f.id AS forum_id,
      t.id AS tag_id,
      COUNT(*) AS usage_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
    GROUP BY f.id, t.id
  ),

  -- Consolidated tag usage per forum (posts + comments)
  forum_tag_usage AS (
    SELECT
      forum_id,
      tag_id,
      SUM(usage_count) AS usage_count
    FROM (
      SELECT * FROM post_tag_usage
      UNION ALL
      SELECT * FROM comment_tag_usage
    ) u
    GROUP BY forum_id, tag_id
  ),

  -- Most used tag per forum (ties broken arbitrarily by ROW_NUMBER)
  forum_top_tag AS (
    SELECT
      ft.forum_id,
      ft.tag_id,
      t.name AS tag_name,
      ft.usage_count,
      ROW_NUMBER() OVER (PARTITION BY ft.forum_id ORDER BY ft.usage_count DESC) AS rn
    FROM forum_tag_usage ft
    JOIN tag t ON t.id = ft.tag_id
  ),

  -- Moderator information per forum
  moderator_info AS (
    SELECT
      f.id AS forum_id,
      p.first_name AS moderator_first_name,
      p.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p ON p.id = f.moderator_person_id
  )
SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  mi.moderator_first_name,
  mi.moderator_last_name,
  COALESCE(pm.post_count, 0) AS post_count,
  pm.avg_post_length,
  COALESCE(cm.comment_count, 0) AS comment_count,
  cm.avg_comment_length,
  COALESCE(mm.member_count, 0) AS member_count,
  tt.tag_name AS top_tag,
  tt.usage_count AS top_tag_usage
FROM forum f
LEFT JOIN post_metrics pm ON pm.forum_id = f.id
LEFT JOIN comment_metrics cm ON cm.forum_id = f.id
LEFT JOIN member_metrics mm ON mm.forum_id = f.id
LEFT JOIN forum_top_tag tt ON tt.forum_id = f.id AND tt.rn = 1
LEFT JOIN moderator_info mi ON mi.forum_id = f.id
ORDER BY (COALESCE(pm.post_count, 0) + COALESCE(cm.comment_count, 0)) DESC
LIMIT 10
