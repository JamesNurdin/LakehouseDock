WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id AS moderator_id,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name,
        p.id AS post_id,
        p.creator_person_id AS post_creator_id,
        p.length AS post_length,
        p.content AS post_content,
        pl.id AS post_location_id,
        pl.name AS post_location_name
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN place pl ON p.location_country_id = pl.id
    LEFT JOIN person p_mod ON p_mod.id = f.moderator_person_id
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS comment_creator_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
),
forum_likes AS (
    SELECT
        f.id AS forum_id,
        pl.person_id AS liker_id,
        pl.post_id AS liked_post_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post pl ON pl.post_id = p.id
),
forum_tags AS (
    SELECT
        f.id AS forum_id,
        pht.tag_id,
        COUNT(*) AS tag_usage_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    GROUP BY f.id, pht.tag_id
)
SELECT
    fp.forum_id,
    fp.forum_title,
    fp.moderator_first_name,
    fp.moderator_last_name,
    COUNT(DISTINCT fp.post_id) AS post_count,
    COALESCE(COUNT(DISTINCT fc.comment_id), 0) AS comment_count,
    AVG(fp.post_length) AS avg_post_length,
    COALESCE(AVG(fc.comment_length), 0) AS avg_comment_length,
    COUNT(DISTINCT fp.post_creator_id) AS distinct_post_authors,
    COALESCE(COUNT(DISTINCT fc.comment_creator_id), 0) AS distinct_comment_authors,
    COUNT(DISTINCT fl.liker_id) AS distinct_likers,
    (
        SELECT ft.tag_id
        FROM forum_tags ft
        WHERE ft.forum_id = fp.forum_id
        ORDER BY ft.tag_usage_count DESC
        LIMIT 1
    ) AS top_tag_id
FROM forum_posts fp
LEFT JOIN forum_comments fc ON fc.forum_id = fp.forum_id
LEFT JOIN forum_likes fl ON fl.forum_id = fp.forum_id
GROUP BY fp.forum_id, fp.forum_title, fp.moderator_first_name, fp.moderator_last_name
ORDER BY post_count DESC
LIMIT 10
