WITH forum_members AS (
    SELECT f.forum_id,
           COUNT(DISTINCT f.person_id) AS member_count
    FROM forum_has_member_person f
    GROUP BY f.forum_id
),
member_friends AS (
    SELECT pk.person_id,
           COUNT(DISTINCT pk.friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) pk
    GROUP BY pk.person_id
),
forum_avg_friends AS (
    SELECT f.forum_id,
           AVG(mf.friend_count) AS avg_friends_per_member
    FROM forum_has_member_person f
    JOIN member_friends mf ON f.person_id = mf.person_id
    GROUP BY f.forum_id
),
forum_member_posts AS (
    SELECT f.forum_id,
           COUNT(DISTINCT po.id) AS post_count,
           AVG(po.length) AS avg_post_length
    FROM forum_has_member_person f
    JOIN person p ON f.person_id = p.id
    JOIN post po ON po.creator_person_id = p.id
    GROUP BY f.forum_id
),
forum_post_likes AS (
    SELECT f.forum_id,
           COUNT(pl.person_id) AS total_post_likes
    FROM forum_has_member_person f
    JOIN person p ON f.person_id = p.id
    JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN person_likes_post pl ON pl.post_id = po.id
    GROUP BY f.forum_id
),
forum_comments AS (
    SELECT f.forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length,
           COUNT(cl.person_id) AS total_comment_likes
    FROM forum_has_member_person f
    JOIN person p ON f.person_id = p.id
    JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN comment c ON c.parent_post_id = po.id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY f.forum_id
)
SELECT fm.forum_id,
       fm.member_count,
       COALESCE(faf.avg_friends_per_member, 0) AS avg_friends_per_member,
       COALESCE(fmp.post_count, 0) AS post_count,
       COALESCE(fmp.avg_post_length, 0) AS avg_post_length,
       COALESCE(fpl.total_post_likes, 0) AS total_post_likes,
       COALESCE(fcmt.comment_count, 0) AS comment_count,
       COALESCE(fcmt.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(fcmt.total_comment_likes, 0) AS total_comment_likes
FROM forum_members fm
LEFT JOIN forum_avg_friends faf   ON fm.forum_id = faf.forum_id
LEFT JOIN forum_member_posts fmp  ON fm.forum_id = fmp.forum_id
LEFT JOIN forum_post_likes fpl    ON fm.forum_id = fpl.forum_id
LEFT JOIN forum_comments fcmt    ON fm.forum_id = fcmt.forum_id
ORDER BY fm.forum_id
