SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(p.post_count, 0) AS post_count,
    p.avg_post_length,
    COALESCE(ptc.post_tag_count, 0) AS post_tag_count,
    COALESCE(ftc.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(plc.post_like_user_count, 0) AS post_like_user_count,
    COALESCE(plc.total_post_likes, 0) AS total_post_likes,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(clc.comment_like_user_count, 0) AS comment_like_user_count,
    COALESCE(clc.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(fc.avg_friends_per_member, 0) AS avg_friends_per_member
FROM forum f
LEFT JOIN (
    SELECT forum_id, COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
) m ON m.forum_id = f.id
LEFT JOIN (
    SELECT container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY container_forum_id
) p ON p.forum_id = f.id
LEFT JOIN (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS post_tag_count
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.container_forum_id
) ptc ON ptc.forum_id = f.id
LEFT JOIN (
    SELECT forum_id, COUNT(DISTINCT tag_id) AS forum_tag_count
    FROM forum_has_tag_tag
    GROUP BY forum_id
) ftc ON ftc.forum_id = f.id
LEFT JOIN (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pl.person_id) AS post_like_user_count,
           COUNT(*) AS total_post_likes
    FROM post p
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
) plc ON plc.forum_id = f.id
LEFT JOIN (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
) cc ON cc.forum_id = f.id
LEFT JOIN (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pcl.person_id) AS comment_like_user_count,
           COUNT(*) AS total_comment_likes
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN person_likes_comment pcl ON pcl.comment_id = c.id
    GROUP BY p.container_forum_id
) clc ON clc.forum_id = f.id
LEFT JOIN (
    SELECT fm.forum_id,
           AVG(fm.friend_cnt) AS avg_friends_per_member
    FROM (
        SELECT fm.forum_id,
               fm.person_id AS member_id,
               COUNT(DISTINCT pk.person2_id) AS friend_cnt
        FROM forum_has_member_person fm
        JOIN person_knows_person pk ON pk.person1_id = fm.person_id
        JOIN forum_has_member_person fm2 ON fm2.forum_id = fm.forum_id
                                         AND fm2.person_id = pk.person2_id
        GROUP BY fm.forum_id, fm.person_id
    ) fm
    GROUP BY fm.forum_id
) fc ON fc.forum_id = f.id
ORDER BY member_count DESC
LIMIT 100
