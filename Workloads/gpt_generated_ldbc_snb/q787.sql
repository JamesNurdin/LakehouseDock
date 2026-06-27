WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.moderator_person_id,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title, f.moderator_person_id
)
SELECT
    forum_id,
    title,
    moderator_person_id,
    post_count,
    total_post_length,
    avg_post_length,
    member_count,
    total_post_length / NULLIF(member_count, 0) AS avg_length_per_member
FROM forum_stats
ORDER BY total_post_length DESC
LIMIT 10
