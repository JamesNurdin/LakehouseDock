WITH forum_posts_agg AS (
    SELECT
        forum.id AS forum_id,
        COUNT(post.id) AS post_count,
        SUM(post.length) AS total_post_length,
        AVG(post.length) AS avg_post_length
    FROM forum
    LEFT JOIN post
        ON post.container_forum_id = forum.id
    GROUP BY forum.id
),
forum_tags_agg AS (
    SELECT
        forum.id AS forum_id,
        COUNT(DISTINCT tag.id) AS distinct_tag_count
    FROM forum
    LEFT JOIN post
        ON post.container_forum_id = forum.id
    LEFT JOIN post_has_tag_tag
        ON post_has_tag_tag.post_id = post.id
    LEFT JOIN tag
        ON post_has_tag_tag.tag_id = tag.id
    GROUP BY forum.id
),
forum_members_agg AS (
    SELECT
        forum.id AS forum_id,
        COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum
    LEFT JOIN forum_has_member_person
        ON forum_has_member_person.forum_id = forum.id
    GROUP BY forum.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fp.total_post_length, 0) AS total_post_length,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(ft.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(fm.member_count, 0) AS member_count
FROM forum f
LEFT JOIN forum_posts_agg fp
    ON fp.forum_id = f.id
LEFT JOIN forum_tags_agg ft
    ON ft.forum_id = f.id
LEFT JOIN forum_members_agg fm
    ON fm.forum_id = f.id
LEFT JOIN person mod
    ON f.moderator_person_id = mod.id
WHERE f.creation_date >= '2022-01-01'
ORDER BY fp.total_post_length DESC
LIMIT 10
