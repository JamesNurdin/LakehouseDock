WITH forum_members AS (
    SELECT fhm.forum_id, fhm.person_id
    FROM forum_has_member_person fhm
),
member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_members fm
    GROUP BY fm.forum_id
),
member_tags AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT pht.tag_id) AS distinct_tag_count
    FROM forum_members fm
    JOIN person p
      ON p.id = fm.person_id
    JOIN person_has_interest_tag pht
      ON pht.person_id = p.id
    GROUP BY fm.forum_id
),
member_likes AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT plc.comment_id) AS member_like_count
    FROM forum_members fm
    JOIN person p
      ON p.id = fm.person_id
    JOIN person_likes_comment plc
      ON plc.person_id = p.id
    GROUP BY fm.forum_id
),
member_students AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT psu.person_id) AS student_member_count
    FROM forum_members fm
    JOIN person p
      ON p.id = fm.person_id
    JOIN person_study_at_university psu
      ON psu.person_id = p.id
    GROUP BY fm.forum_id
),
member_workers AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT pwc.person_id) AS worker_member_count
    FROM forum_members fm
    JOIN person p
      ON p.id = fm.person_id
    JOIN person_work_at_company pwc
      ON pwc.person_id = p.id
    GROUP BY fm.forum_id
),
member_cities AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT pl.id) AS distinct_city_count
    FROM forum_members fm
    JOIN person p
      ON p.id = fm.person_id
    JOIN place pl
      ON pl.id = p.location_city_id
    GROUP BY fm.forum_id
),
forum_mod AS (
    SELECT f.id AS forum_id,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p
      ON p.id = f.moderator_person_id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       mod.moderator_first_name,
       mod.moderator_last_name,
       mc.member_count,
       mt.distinct_tag_count,
       ml.member_like_count,
       ms.student_member_count,
       mw.worker_member_count,
       mcit.distinct_city_count
FROM forum f
LEFT JOIN forum_mod mod
  ON mod.forum_id = f.id
LEFT JOIN member_counts mc
  ON mc.forum_id = f.id
LEFT JOIN member_tags mt
  ON mt.forum_id = f.id
LEFT JOIN member_likes ml
  ON ml.forum_id = f.id
LEFT JOIN member_students ms
  ON ms.forum_id = f.id
LEFT JOIN member_workers mw
  ON mw.forum_id = f.id
LEFT JOIN member_cities mcit
  ON mcit.forum_id = f.id
ORDER BY f.id
