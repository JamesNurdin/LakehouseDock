WITH member_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),

tag_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    GROUP BY f.id
),

post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS total_posts,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creators,
        SUM(CASE WHEN p.length > 1000 THEN 1 ELSE 0 END) AS long_post_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    WHERE p.language = 'en'
    GROUP BY f.id
),

moderators AS (
    SELECT
        f.id AS forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
)

SELECT
    f.id,
    f.title,
    m.moderator_first_name,
    m.moderator_last_name,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ps.long_post_count, 0) AS long_post_count,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(ps.distinct_creators, 0) AS distinct_post_creators
FROM forum f
LEFT JOIN member_counts mc ON mc.forum_id = f.id
LEFT JOIN tag_counts tc ON tc.forum_id = f.id
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN moderators m ON m.forum_id = f.id
ORDER BY total_posts DESC, f.id
