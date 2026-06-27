WITH
    forum_mod AS (
        SELECT
            f.id AS forum_id,
            f.title,
            p.first_name,
            p.last_name
        FROM forum f
        JOIN person p
            ON f.moderator_person_id = p.id
    ),
    forum_member_counts AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    forum_post_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS post_count,
            AVG(p.length) AS avg_post_length,
            SUM(p.length) AS total_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    forum_comment_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS comment_count
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_tag_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT pt.tag_id) AS distinct_tag_count
        FROM post_has_tag_tag pt
        JOIN post p
            ON pt.post_id = p.id
        GROUP BY p.container_forum_id
    )
SELECT
    fm.forum_id,
    fm.title,
    CONCAT(fm.first_name, ' ', fm.last_name) AS moderator_name,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(ft.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(fmbr.member_count, 0) AS member_count
FROM forum_mod fm
LEFT JOIN forum_member_counts fmbr
    ON fm.forum_id = fmbr.forum_id
LEFT JOIN forum_post_stats fp
    ON fm.forum_id = fp.forum_id
LEFT JOIN forum_comment_counts fc
    ON fm.forum_id = fc.forum_id
LEFT JOIN forum_tag_counts ft
    ON fm.forum_id = ft.forum_id
ORDER BY post_count DESC
LIMIT 100
