WITH forum_info AS (
   SELECT
      f.id AS forum_id,
      f.title,
      f.creation_date AS forum_creation_date,
      mod.first_name AS moderator_first_name,
      mod.last_name AS moderator_last_name
   FROM forum f
   LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
member_counts AS (
   SELECT
      fm.forum_id,
      COUNT(DISTINCT fm.person_id) AS member_count,
      COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN p.id END) AS female_member_count
   FROM forum_has_member_person fm
   JOIN person p ON fm.person_id = p.id
   GROUP BY fm.forum_id
),
post_stats AS (
   SELECT
      p.container_forum_id AS forum_id,
      COUNT(DISTINCT p.id) AS post_count,
      AVG(p.length) AS avg_post_length
   FROM post p
   WHERE p.language = 'en'
   GROUP BY p.container_forum_id
),
tag_occurrence AS (
   SELECT
      ft.forum_id,
      t.name AS tag_name,
      COUNT(*) AS occurrence
   FROM forum_has_tag_tag ft
   JOIN tag t ON ft.tag_id = t.id
   GROUP BY ft.forum_id, t.name
),
tag_counts AS (
   SELECT
      forum_id,
      COUNT(DISTINCT tag_name) AS tag_count
   FROM tag_occurrence
   GROUP BY forum_id
),
top_tag AS (
   SELECT
      forum_id,
      tag_name,
      occurrence,
      ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY occurrence DESC, tag_name) AS rn
   FROM tag_occurrence
)
SELECT
   fi.forum_id,
   fi.title,
   fi.forum_creation_date,
   fi.moderator_first_name,
   fi.moderator_last_name,
   COALESCE(mc.member_count, 0) AS member_count,
   COALESCE(mc.female_member_count, 0) AS female_member_count,
   COALESCE(ps.post_count, 0) AS post_count,
   ps.avg_post_length,
   COALESCE(tc.tag_count, 0) AS tag_count,
   tt.tag_name AS top_tag_name
FROM forum_info fi
LEFT JOIN member_counts mc ON fi.forum_id = mc.forum_id
LEFT JOIN post_stats ps ON fi.forum_id = ps.forum_id
LEFT JOIN tag_counts tc ON fi.forum_id = tc.forum_id
LEFT JOIN (
   SELECT forum_id, tag_name
   FROM top_tag
   WHERE rn = 1
) tt ON fi.forum_id = tt.forum_id
ORDER BY member_count DESC
LIMIT 20
