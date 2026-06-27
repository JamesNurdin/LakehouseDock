WITH member_agg AS (
  SELECT
    fm.forum_id,
    COUNT(DISTINCT fm.person_id) AS member_count,
    SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS male_member_count,
    SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_member_count
  FROM forum_has_member_person fm
  LEFT JOIN person p
    ON fm.person_id = p.id
  GROUP BY fm.forum_id
),

tag_agg AS (
  SELECT
    ft.forum_id,
    COUNT(DISTINCT ft.tag_id) AS tag_count
  FROM forum_has_tag_tag ft
  GROUP BY ft.forum_id
)
SELECT
  f.id AS forum_id,
  f.title,
  mod.first_name AS moderator_first_name,
  mod.last_name  AS moderator_last_name,
  mod.gender    AS moderator_gender,
  COALESCE(m.member_count, 0)        AS member_count,
  COALESCE(t.tag_count, 0)           AS tag_count,
  COALESCE(m.male_member_count, 0)   AS male_member_count,
  COALESCE(m.female_member_count, 0) AS female_member_count
FROM forum f
LEFT JOIN person mod
  ON f.moderator_person_id = mod.id
LEFT JOIN member_agg m
  ON f.id = m.forum_id
LEFT JOIN tag_agg t
  ON f.id = t.forum_id
ORDER BY member_count DESC, tag_count DESC
LIMIT 100
