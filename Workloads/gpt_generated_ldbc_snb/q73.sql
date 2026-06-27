WITH member_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        SUM(CASE WHEN per.gender = 'male' THEN 1 ELSE 0 END) AS male_member_count,
        SUM(CASE WHEN per.gender = 'female' THEN 1 ELSE 0 END) AS female_member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    LEFT JOIN person per ON per.id = fm.person_id
    GROUP BY f.id
),
forum_tag_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum f
    LEFT JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    GROUP BY f.id
),
member_interest_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_member_interest_tag_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    LEFT JOIN person per ON per.id = fm.person_id
    LEFT JOIN person_has_interest_tag pit ON pit.person_id = per.id
    GROUP BY f.id
),
post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT pl.id) AS distinct_post_country_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN place pl ON pl.id = p.location_country_id
    GROUP BY f.id
),
member_like_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT plc.comment_id) AS distinct_comments_liked_by_members
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    LEFT JOIN person per ON per.id = fm.person_id
    LEFT JOIN person_likes_comment plc ON plc.person_id = per.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    f.moderator_person_id AS moderator_id,
    moderator.first_name AS moderator_first_name,
    moderator.last_name AS moderator_last_name,
    moderator.gender AS moderator_gender,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(m.male_member_count, 0) AS male_member_count,
    COALESCE(m.female_member_count, 0) AS female_member_count,
    COALESCE(t.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(i.distinct_member_interest_tag_count, 0) AS distinct_member_interest_tag_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(p.distinct_post_country_count, 0) AS distinct_post_country_count,
    COALESCE(l.distinct_comments_liked_by_members, 0) AS distinct_comments_liked_by_members
FROM forum f
LEFT JOIN member_stats m ON m.forum_id = f.id
LEFT JOIN forum_tag_stats t ON t.forum_id = f.id
LEFT JOIN member_interest_stats i ON i.forum_id = f.id
LEFT JOIN post_stats p ON p.forum_id = f.id
LEFT JOIN member_like_stats l ON l.forum_id = f.id
LEFT JOIN person moderator ON moderator.id = f.moderator_person_id
ORDER BY p.post_count DESC NULLS LAST
LIMIT 100
