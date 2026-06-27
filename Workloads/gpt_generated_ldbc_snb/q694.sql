WITH tag_counts AS (
    SELECT
        forum_has_tag_tag.forum_id,
        COUNT(DISTINCT forum_has_tag_tag.tag_id) AS tag_count
    FROM forum_has_tag_tag
    GROUP BY forum_has_tag_tag.forum_id
),
post_stats AS (
    SELECT
        post.container_forum_id,
        COUNT(DISTINCT post.id) AS post_count,
        AVG(post.length) AS avg_post_length,
        COUNT(DISTINCT post.creator_person_id) AS distinct_creator_count
    FROM post
    GROUP BY post.container_forum_id
)
SELECT
    f.title,
    mod_person.first_name,
    mod_person.last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(ps.distinct_creator_count, 0) AS distinct_creator_count
FROM forum f
LEFT JOIN tag_counts tc
    ON tc.forum_id = f.id
LEFT JOIN post_stats ps
    ON ps.container_forum_id = f.id
LEFT JOIN person mod_person
    ON f.moderator_person_id = mod_person.id
ORDER BY post_count DESC
LIMIT 100
