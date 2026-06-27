WITH
    forum_members AS (
        SELECT f.id AS forum_id,
               f.title,
               f.moderator_person_id,
               fm.person_id AS member_id
        FROM forum f
        JOIN forum_has_member_person fm
          ON fm.forum_id = f.id
    ),
    member_counts AS (
        SELECT forum_id,
               COUNT(DISTINCT member_id) AS member_count
        FROM forum_members
        GROUP BY forum_id
    ),
    friend_counts_per_person AS (
        SELECT p.id AS person_id,
               COUNT(DISTINCT CASE WHEN pk.person1_id = p.id THEN pk.person2_id ELSE pk.person1_id END) AS friend_count
        FROM person p
        LEFT JOIN person_knows_person pk
          ON pk.person1_id = p.id OR pk.person2_id = p.id
        GROUP BY p.id
    ),
    forum_friend_agg AS (
        SELECT fm.forum_id,
               AVG(pfc.friend_count) AS avg_friends_per_member
        FROM forum_members fm
        JOIN friend_counts_per_person pfc
          ON pfc.person_id = fm.member_id
        GROUP BY fm.forum_id
    ),
    member_comment_stats AS (
        SELECT fm.forum_id,
               COUNT(plc.person_id) AS total_likes_on_member_comments,
               AVG(c.length) AS avg_comment_length_by_members
        FROM forum_members fm
        JOIN comment c
          ON c.creator_person_id = fm.member_id
        LEFT JOIN person_likes_comment plc
          ON plc.comment_id = c.id
        GROUP BY fm.forum_id
    ),
    forum_interest_counts AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT pit.tag_id) AS distinct_interest_count
        FROM forum_members fm
        JOIN person_has_interest_tag pit
          ON pit.person_id = fm.member_id
        GROUP BY fm.forum_id
    ),
    moderator_info AS (
        SELECT p.id AS moderator_person_id,
               p.first_name,
               p.last_name
        FROM person p
    )
SELECT f.id AS forum_id,
       f.title,
       mi.first_name AS moderator_first_name,
       mi.last_name AS moderator_last_name,
       mc.member_count,
       ffa.avg_friends_per_member,
       mcs.avg_comment_length_by_members,
       mcs.total_likes_on_member_comments,
       fic.distinct_interest_count
FROM forum f
JOIN member_counts mc
  ON mc.forum_id = f.id
JOIN forum_friend_agg ffa
  ON ffa.forum_id = f.id
JOIN member_comment_stats mcs
  ON mcs.forum_id = f.id
JOIN forum_interest_counts fic
  ON fic.forum_id = f.id
JOIN moderator_info mi
  ON mi.moderator_person_id = f.moderator_person_id
ORDER BY mc.member_count DESC
LIMIT 100
