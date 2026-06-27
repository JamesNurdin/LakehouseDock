WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS total_posts,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(pl.person_id) AS total_post_likes
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_stats AS (
    SELECT
        fs.forum_id,
        fs.forum_title,
        fs.total_posts,
        fs.avg_post_length,
        COALESCE(fl.total_post_likes, 0) AS total_post_likes
    FROM forum_stats fs
    LEFT JOIN forum_likes fl
        ON fl.forum_id = fs.forum_id
),
member_tag_counts AS (
    SELECT
        fm.forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS members_with_tag
    FROM forum_has_member_person fm
    JOIN person p
        ON p.id = fm.person_id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    JOIN tag t
        ON t.id = pit.tag_id
    GROUP BY fm.forum_id, t.id, t.name
),
ranked_tags AS (
    SELECT
        mtc.forum_id,
        mtc.tag_id,
        mtc.tag_name,
        mtc.members_with_tag,
        ROW_NUMBER() OVER (PARTITION BY mtc.forum_id ORDER BY mtc.members_with_tag DESC) AS tag_rank
    FROM member_tag_counts mtc
)
SELECT
    fps.forum_id,
    fps.forum_title,
    fps.total_posts,
    fps.avg_post_length,
    fps.total_post_likes,
    rt.tag_id,
    rt.tag_name,
    rt.members_with_tag
FROM forum_post_stats fps
JOIN ranked_tags rt
    ON rt.forum_id = fps.forum_id
WHERE rt.tag_rank <= 5
ORDER BY fps.forum_id, rt.tag_rank
