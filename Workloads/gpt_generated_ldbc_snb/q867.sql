WITH member_counts AS (
  SELECT
    f.id AS forum_id,
    COUNT(DISTINCT fm.person_id) AS member_count,
    SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS male_member_count,
    SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_member_count
  FROM forum f
  JOIN forum_has_member_person fm ON fm.forum_id = f.id
  JOIN person p                     ON p.id = fm.person_id
  GROUP BY f.id
),
post_stats AS (
  SELECT
    f.id AS forum_id,
    COUNT(DISTINCT po.id) AS post_count,
    AVG(po.length)        AS avg_post_length
  FROM forum f
  JOIN post po ON po.container_forum_id = f.id
  GROUP BY f.id
),
post_tag_stats AS (
  SELECT
    f.id AS forum_id,
    COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count,
    COUNT(DISTINCT tc.id)    AS distinct_post_tag_class_count
  FROM forum f
  JOIN post po               ON po.container_forum_id = f.id
  JOIN post_has_tag_tag pt   ON pt.post_id = po.id
  JOIN tag t                 ON t.id = pt.tag_id
  JOIN tag_class tc          ON tc.id = t.type_tag_class_id
  GROUP BY f.id
),
forum_tag_stats AS (
  SELECT
    f.id AS forum_id,
    COUNT(DISTINCT ft.tag_id) AS distinct_forum_tag_count,
    COUNT(DISTINCT ftc.id)    AS distinct_forum_tag_class_count
  FROM forum f
  JOIN forum_has_tag_tag ft   ON ft.forum_id = f.id
  JOIN tag ftg                ON ftg.id = ft.tag_id
  JOIN tag_class ftc          ON ftc.id = ftg.type_tag_class_id
  GROUP BY f.id
),
member_interest_stats AS (
  SELECT
    f.id AS forum_id,
    COUNT(DISTINCT it.tag_id) AS distinct_member_interest_tag_count,
    COUNT(DISTINCT itc.id)    AS distinct_member_interest_tag_class_count
  FROM forum f
  JOIN forum_has_member_person fm ON fm.forum_id = f.id
  JOIN person p                    ON p.id = fm.person_id
  JOIN person_has_interest_tag it  ON it.person_id = p.id
  JOIN tag itg                     ON itg.id = it.tag_id
  JOIN tag_class itc               ON itc.id = itg.type_tag_class_id
  GROUP BY f.id
)
SELECT
  f.id   AS forum_id,
  f.title AS forum_title,
  COALESCE(mc.member_count, 0)                         AS member_count,
  COALESCE(mc.male_member_count, 0)                  AS male_member_count,
  COALESCE(mc.female_member_count, 0)                AS female_member_count,
  COALESCE(ps.post_count, 0)                         AS post_count,
  COALESCE(ps.avg_post_length, 0)                    AS avg_post_length,
  COALESCE(pts.distinct_post_tag_count, 0)           AS distinct_post_tag_count,
  COALESCE(pts.distinct_post_tag_class_count, 0)     AS distinct_post_tag_class_count,
  COALESCE(fts.distinct_forum_tag_count, 0)          AS distinct_forum_tag_count,
  COALESCE(fts.distinct_forum_tag_class_count, 0)    AS distinct_forum_tag_class_count,
  COALESCE(mis.distinct_member_interest_tag_count, 0) AS distinct_member_interest_tag_count,
  COALESCE(mis.distinct_member_interest_tag_class_count, 0) AS distinct_member_interest_tag_class_count
FROM forum f
LEFT JOIN member_counts mc          ON mc.forum_id = f.id
LEFT JOIN post_stats ps             ON ps.forum_id = f.id
LEFT JOIN post_tag_stats pts        ON pts.forum_id = f.id
LEFT JOIN forum_tag_stats fts       ON fts.forum_id = f.id
LEFT JOIN member_interest_stats mis ON mis.forum_id = f.id
ORDER BY post_count DESC
LIMIT 20
