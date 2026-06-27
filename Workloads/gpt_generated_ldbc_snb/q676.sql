WITH member_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
member_interest_tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT pit.tag_id) AS member_interest_tag_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    JOIN person p ON p.id = fm.person_id
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
    GROUP BY f.id
),
post_stats AS (
    SELECT f.id AS forum_id,
           COUNT(p.id) AS post_count,
           AVG(p.length) AS avg_post_length,
           COUNT(plp.person_id) AS total_likes
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id
),
tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    GROUP BY f.id
)
SELECT f.id,
       f.title,
       mod.first_name AS moderator_first_name,
       mod.last_name AS moderator_last_name,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(mit.member_interest_tag_count, 0) AS member_interest_tag_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(p.total_likes, 0) AS total_likes,
       COALESCE(t.tag_count, 0) AS tag_count
FROM forum f
LEFT JOIN member_counts m ON m.forum_id = f.id
LEFT JOIN member_interest_tag_counts mit ON mit.forum_id = f.id
LEFT JOIN post_stats p ON p.forum_id = f.id
LEFT JOIN tag_counts t ON t.forum_id = f.id
LEFT JOIN person mod ON mod.id = f.moderator_person_id
ORDER BY f.id
