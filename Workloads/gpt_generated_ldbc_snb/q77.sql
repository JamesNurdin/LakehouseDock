WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors,
        COUNT(DISTINCT ch.tag_id) AS comment_tag_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag ch
        ON ch.comment_id = c.id
    GROUP BY f.id
),
post_tags AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS post_tag_count,
        COUNT(DISTINCT p.id) AS post_with_tags_count
    FROM post p
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(pl.person_id) AS post_like_count
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(cl.person_id) AS comment_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
)
SELECT
    fp.forum_id,
    fp.title,
    fp.forum_creation_date,
    fp.post_count,
    fp.total_post_length,
    fp.distinct_post_authors,
    fc.comment_count,
    fc.distinct_comment_authors,
    pl.post_like_count,
    cl.comment_like_count,
    pt.post_tag_count,
    pt.post_with_tags_count,
    fc.comment_tag_count,
    fm.member_count,
    f.moderator_person_id,
    fp.total_post_length / NULLIF(fp.post_count, 0) AS avg_post_length,
    pt.post_tag_count / NULLIF(pt.post_with_tags_count, 0) AS avg_tags_per_post,
    fc.comment_tag_count / NULLIF(fc.comment_count, 0) AS avg_tags_per_comment
FROM forum_posts fp
LEFT JOIN forum_comments fc
    ON fc.forum_id = fp.forum_id
LEFT JOIN post_likes pl
    ON pl.forum_id = fp.forum_id
LEFT JOIN comment_likes cl
    ON cl.forum_id = fp.forum_id
LEFT JOIN post_tags pt
    ON pt.forum_id = fp.forum_id
LEFT JOIN forum_members fm
    ON fm.forum_id = fp.forum_id
LEFT JOIN forum f
    ON f.id = fp.forum_id
ORDER BY fp.post_count DESC
LIMIT 20
