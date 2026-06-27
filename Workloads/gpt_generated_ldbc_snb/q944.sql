WITH forum_members AS (
    SELECT fm.forum_id,
           fm.person_id AS member_id
    FROM forum_has_member_person fm
),
member_friends AS (
    SELECT fm.forum_id,
           fm.member_id,
           COUNT(DISTINCT kp.person2_id) AS friend_count
    FROM forum_members fm
    LEFT JOIN person_knows_person kp
      ON kp.person1_id = fm.member_id
    GROUP BY fm.forum_id, fm.member_id
),
member_comments AS (
    SELECT fm.forum_id,
           fm.member_id,
           c.id AS comment_id,
           c.length AS comment_length
    FROM forum_members fm
    JOIN comment c
      ON c.creator_person_id = fm.member_id
),
comment_likes AS (
    SELECT mc.forum_id,
           mc.comment_id,
           COUNT(plc.person_id) AS like_count
    FROM member_comments mc
    LEFT JOIN person_likes_comment plc
      ON plc.comment_id = mc.comment_id
    GROUP BY mc.forum_id, mc.comment_id
),
forum_distinct_likers AS (
    SELECT mc.forum_id,
           COUNT(DISTINCT plc.person_id) AS distinct_liker_count
    FROM member_comments mc
    LEFT JOIN person_likes_comment plc
      ON plc.comment_id = mc.comment_id
    GROUP BY mc.forum_id
),
moderator AS (
    SELECT f.id AS forum_id,
           p.id AS moderator_id,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p
      ON f.moderator_person_id = p.id
)
SELECT f.id AS forum_id,
       f.title,
       mdr.moderator_first_name,
       mdr.moderator_last_name,
       COUNT(DISTINCT fm.member_id) AS member_count,
       COUNT(DISTINCT mc.comment_id) AS comment_count,
       AVG(mc.comment_length) AS avg_comment_length,
       COALESCE(SUM(cl.like_count), 0) AS total_likes,
       COALESCE(fd.distinct_liker_count, 0) AS distinct_likers,
       AVG(mf.friend_count) AS avg_friends_per_member
FROM forum f
JOIN forum_members fm
  ON fm.forum_id = f.id
LEFT JOIN moderator mdr
  ON mdr.forum_id = f.id
LEFT JOIN member_friends mf
  ON mf.forum_id = fm.forum_id AND mf.member_id = fm.member_id
LEFT JOIN member_comments mc
  ON mc.forum_id = fm.forum_id AND mc.member_id = fm.member_id
LEFT JOIN comment_likes cl
  ON cl.forum_id = mc.forum_id AND cl.comment_id = mc.comment_id
LEFT JOIN forum_distinct_likers fd
  ON fd.forum_id = f.id
GROUP BY f.id,
         f.title,
         mdr.moderator_first_name,
         mdr.moderator_last_name,
         fd.distinct_liker_count
ORDER BY total_likes DESC
LIMIT 10
