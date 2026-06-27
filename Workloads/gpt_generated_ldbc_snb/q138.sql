WITH forum_member_counts AS (
    SELECT f.id AS forum_id,
           f.title,
           f.creation_date,
           f.moderator_person_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date, f.moderator_person_id
),
forum_member_likes AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT pl.post_id) AS post_like_count,
           COUNT(DISTINCT cl.comment_id) AS comment_like_count
    FROM forum_has_member_person fm
    JOIN person p ON p.id = fm.person_id
    LEFT JOIN person_likes_post pl ON pl.person_id = p.id
    LEFT JOIN person_likes_comment cl ON cl.person_id = p.id
    GROUP BY fm.forum_id
),
forum_member_tags AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT pt.tag_id) AS distinct_tag_count
    FROM forum_has_member_person fm
    JOIN person p ON p.id = fm.person_id
    JOIN person_has_interest_tag pt ON pt.person_id = p.id
    GROUP BY fm.forum_id
)
SELECT fmc.title,
       fmc.creation_date,
       fmc.member_count,
       COALESCE(fml.post_like_count, 0) + COALESCE(fml.comment_like_count, 0) AS total_likes,
       COALESCE(fmt.distinct_tag_count, 0) AS distinct_tags,
       mod.first_name,
       mod.last_name
FROM forum_member_counts fmc
LEFT JOIN forum_member_likes fml ON fml.forum_id = fmc.forum_id
LEFT JOIN forum_member_tags fmt ON fmt.forum_id = fmc.forum_id
JOIN person mod ON mod.id = fmc.moderator_person_id
ORDER BY total_likes DESC
LIMIT 10
