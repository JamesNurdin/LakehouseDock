WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title,
           f.moderator_person_id
    FROM forum f
),
moderator_info AS (
    SELECT fb.forum_id,
           fb.title,
           CONCAT(p.first_name, ' ', p.last_name) AS moderator_name
    FROM forum_base fb
    JOIN person p
      ON fb.moderator_person_id = p.id
),
member_counts AS (
    SELECT fb.forum_id,
           COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_base fb
    LEFT JOIN forum_has_member_person fhm
      ON fhm.forum_id = fb.forum_id
    GROUP BY fb.forum_id
),
active_member_friends AS (
    -- members who have at least one friend that is also a member of the same forum
    SELECT DISTINCT fb.forum_id, fhm_member.person_id AS member_id
    FROM forum_base fb
    JOIN forum_has_member_person fhm_member
      ON fhm_member.forum_id = fb.forum_id
    JOIN person_knows_person pkp
      ON pkp.person1_id = fhm_member.person_id
    JOIN person p_friend
      ON p_friend.id = pkp.person2_id
    JOIN forum_has_member_person fhm_friend
      ON fhm_friend.forum_id = fb.forum_id
     AND fhm_friend.person_id = p_friend.id
    UNION
    SELECT DISTINCT fb.forum_id, fhm_member.person_id AS member_id
    FROM forum_base fb
    JOIN forum_has_member_person fhm_member
      ON fhm_member.forum_id = fb.forum_id
    JOIN person_knows_person pkp
      ON pkp.person2_id = fhm_member.person_id
    JOIN person p_friend
      ON p_friend.id = pkp.person1_id
    JOIN forum_has_member_person fhm_friend
      ON fhm_friend.forum_id = fb.forum_id
     AND fhm_friend.person_id = p_friend.id
),
active_member_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT member_id) AS active_members_with_friends
    FROM active_member_friends
    GROUP BY forum_id
),
post_stats AS (
    SELECT fb.forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum_base fb
    JOIN post p
      ON p.container_forum_id = fb.forum_id
    GROUP BY fb.forum_id
),
like_stats AS (
    SELECT fb.forum_id,
           COUNT(plp.post_id) AS total_likes,
           COUNT(DISTINCT plp.person_id) AS distinct_likers
    FROM forum_base fb
    JOIN post p
      ON p.container_forum_id = fb.forum_id
    JOIN person_likes_post plp
      ON plp.post_id = p.id
    GROUP BY fb.forum_id
)
SELECT mi.forum_id,
       mi.title,
       mi.moderator_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(amc.active_members_with_friends, 0) AS active_members_with_friends,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length,
       COALESCE(ls.total_likes, 0) AS total_likes,
       COALESCE(ls.distinct_likers, 0) AS distinct_likers
FROM moderator_info mi
LEFT JOIN member_counts mc
  ON mc.forum_id = mi.forum_id
LEFT JOIN active_member_counts amc
  ON amc.forum_id = mi.forum_id
LEFT JOIN post_stats ps
  ON ps.forum_id = mi.forum_id
LEFT JOIN like_stats ls
  ON ls.forum_id = mi.forum_id
ORDER BY post_count DESC
LIMIT 10
