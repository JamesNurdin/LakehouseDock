WITH forum_members AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           p.id AS member_id
    FROM forum f
    JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
    JOIN person p ON fmp.person_id = p.id
),
member_friends AS (
    SELECT fm.forum_id,
           fm.member_id,
           COUNT(DISTINCT kp.person2_id) AS friend_count
    FROM forum_members fm
    LEFT JOIN person_knows_person kp ON kp.person1_id = fm.member_id
    GROUP BY fm.forum_id, fm.member_id
),
forum_friend_stats AS (
    SELECT mf.forum_id,
           AVG(mf.friend_count) AS avg_friends_per_member
    FROM member_friends mf
    GROUP BY mf.forum_id
),
member_comments AS (
    SELECT fm.forum_id,
           fm.member_id,
           c.id AS comment_id,
           c.length AS comment_length,
           c.location_country_id
    FROM forum_members fm
    JOIN comment c ON c.creator_person_id = fm.member_id
),
comment_likes AS (
    SELECT mc.forum_id,
           mc.comment_id,
           COUNT(plc.person_id) AS like_count
    FROM member_comments mc
    LEFT JOIN person_likes_comment plc ON plc.comment_id = mc.comment_id
    GROUP BY mc.forum_id, mc.comment_id
),
forum_comment_stats AS (
    SELECT mc.forum_id,
           COUNT(DISTINCT mc.comment_id) AS total_comments,
           AVG(mc.comment_length) AS avg_comment_length,
           SUM(COALESCE(cl.like_count, 0)) AS total_likes
    FROM member_comments mc
    LEFT JOIN comment_likes cl ON cl.forum_id = mc.forum_id AND cl.comment_id = mc.comment_id
    GROUP BY mc.forum_id
),
forum_member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.member_id) AS num_members
    FROM forum_members fm
    GROUP BY fm.forum_id
),
comment_countries AS (
    SELECT mc.forum_id,
           pl.name AS country_name,
           COUNT(*) AS comment_cnt
    FROM member_comments mc
    JOIN place pl ON mc.location_country_id = pl.id
    GROUP BY mc.forum_id, pl.name
),
ranked_countries AS (
    SELECT cc.forum_id,
           cc.country_name,
           cc.comment_cnt,
           ROW_NUMBER() OVER (PARTITION BY cc.forum_id ORDER BY cc.comment_cnt DESC) AS rn
    FROM comment_countries cc
),
forum_top_countries AS (
    SELECT rc.forum_id,
           array_agg(rc.country_name ORDER BY rc.comment_cnt DESC) FILTER (WHERE rc.rn <= 3) AS top_3_countries
    FROM ranked_countries rc
    GROUP BY rc.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(mcnt.num_members, 0) AS num_members,
    COALESCE(ffs.avg_friends_per_member, 0) AS avg_friends_per_member,
    COALESCE(fcs.total_comments, 0) AS total_comments_by_members,
    COALESCE(fcs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fcs.total_likes, 0) AS total_likes_on_member_comments,
    ftc.top_3_countries
FROM forum f
LEFT JOIN forum_member_counts mcnt ON mcnt.forum_id = f.id
LEFT JOIN forum_friend_stats ffs ON ffs.forum_id = f.id
LEFT JOIN forum_comment_stats fcs ON fcs.forum_id = f.id
LEFT JOIN forum_top_countries ftc ON ftc.forum_id = f.id
ORDER BY f.id
