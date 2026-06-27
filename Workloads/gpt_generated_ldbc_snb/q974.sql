WITH
  post_stats AS (
    SELECT
      f.id AS forum_id,
      COUNT(p.id) AS post_count,
      AVG(p.length) AS avg_post_length,
      COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
  ),
  comment_stats AS (
    SELECT
      f.id AS forum_id,
      COUNT(c.id) AS comment_count,
      AVG(c.length) AS avg_comment_length,
      COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
  ),
  participant_stats AS (
    SELECT
      forum_id,
      COUNT(DISTINCT person_id) AS distinct_participants
    FROM (
      SELECT f.id AS forum_id, p.creator_person_id AS person_id
      FROM forum f
      LEFT JOIN post p ON p.container_forum_id = f.id
      WHERE p.creator_person_id IS NOT NULL
      UNION ALL
      SELECT f.id AS forum_id, c.creator_person_id AS person_id
      FROM forum f
      LEFT JOIN post p ON p.container_forum_id = f.id
      LEFT JOIN comment c ON c.parent_post_id = p.id
      WHERE c.creator_person_id IS NOT NULL
    ) t
    GROUP BY forum_id
  ),
  forum_tag_counts AS (
    SELECT
      f.id AS forum_id,
      t.id AS tag_id,
      t.name AS tag_name,
      COUNT(*) AS tag_usage
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pht ON pht.post_id = p.id
    LEFT JOIN tag t ON t.id = pht.tag_id
    GROUP BY f.id, t.id, t.name

    UNION ALL

    SELECT
      f.id AS forum_id,
      t.id AS tag_id,
      t.name AS tag_name,
      COUNT(*) AS tag_usage
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    LEFT JOIN tag t ON t.id = cht.tag_id
    GROUP BY f.id, t.id, t.name
  ),
  forum_top_tag AS (
    SELECT
      forum_id,
      tag_name,
      tag_usage,
      ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM forum_tag_counts
  )
SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  COALESCE(ps.post_count, 0) AS post_count,
  COALESCE(cs.comment_count, 0) AS comment_count,
  ps.avg_post_length,
  cs.avg_comment_length,
  dps.distinct_participants,
  pt.tag_name AS top_tag,
  pt.tag_usage AS top_tag_usage
FROM forum f
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN comment_stats cs ON cs.forum_id = f.id
LEFT JOIN participant_stats dps ON dps.forum_id = f.id
LEFT JOIN forum_top_tag pt ON pt.forum_id = f.id AND pt.rn = 1
ORDER BY post_count DESC
LIMIT 100
