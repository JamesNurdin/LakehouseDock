WITH forum_moderator AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date,
        p.first_name,
        p.last_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
),
forum_members AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
forum_posts AS (
    SELECT
        container_forum_id AS forum_id,
        COUNT(DISTINCT id) AS post_count
    FROM post
    GROUP BY container_forum_id
),
forum_post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS like_count
    FROM post p
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_tags AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pht.tag_id) AS distinct_tag_count
    FROM post p
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fm.forum_id,
    fm.title,
    fm.creation_date,
    fm.first_name AS moderator_first_name,
    fm.last_name AS moderator_last_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(po.post_count, 0) AS post_count,
    COALESCE(pl.like_count, 0) AS post_like_count,
    COALESCE(tg.distinct_tag_count, 0) AS distinct_tag_count
FROM forum_moderator fm
LEFT JOIN forum_members m ON fm.forum_id = m.forum_id
LEFT JOIN forum_posts po ON fm.forum_id = po.forum_id
LEFT JOIN forum_post_likes pl ON fm.forum_id = pl.forum_id
LEFT JOIN forum_post_tags tg ON fm.forum_id = tg.forum_id
ORDER BY member_count DESC, forum_id
