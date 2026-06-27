WITH
    forum_basic AS (
        SELECT id,
               title,
               creation_date
        FROM forum
    ),
    member_counts AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    post_stats AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT p.id) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    post_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT pl.person_id) AS post_like_count
        FROM post p
        JOIN person_likes_post pl ON pl.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT pc.person_id) AS comment_like_count
        FROM post p
        JOIN comment c ON c.parent_post_id = p.id
        JOIN person_likes_comment pc ON pc.comment_id = c.id
        GROUP BY p.container_forum_id
    ),
    tag_counts AS (
        SELECT ft.forum_id,
               COUNT(DISTINCT ft.tag_id) AS tag_count
        FROM forum_has_tag_tag ft
        GROUP BY ft.forum_id
    ),
    member_interest_tag_counts AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT pit.tag_id) AS member_interest_tag_count
        FROM forum_has_member_person fm
        JOIN person per ON fm.person_id = per.id
        JOIN person_has_interest_tag pit ON pit.person_id = per.id
        GROUP BY fm.forum_id
    )
SELECT
    fb.id,
    fb.title,
    fb.creation_date,
    COALESCE(mc.member_count, 0)                     AS member_count,
    COALESCE(ps.post_count, 0)                       AS post_count,
    COALESCE(ps.avg_post_length, 0)                  AS avg_post_length,
    COALESCE(plc.post_like_count, 0)                AS post_like_count,
    COALESCE(clc.comment_like_count, 0)             AS comment_like_count,
    COALESCE(tc.tag_count, 0)                        AS tag_count,
    COALESCE(mitc.member_interest_tag_count, 0)     AS member_interest_tag_count
FROM forum_basic fb
LEFT JOIN member_counts mc ON mc.forum_id = fb.id
LEFT JOIN post_stats ps ON ps.forum_id = fb.id
LEFT JOIN post_like_counts plc ON plc.forum_id = fb.id
LEFT JOIN comment_like_counts clc ON clc.forum_id = fb.id
LEFT JOIN tag_counts tc ON tc.forum_id = fb.id
LEFT JOIN member_interest_tag_counts mitc ON mitc.forum_id = fb.id
ORDER BY member_count DESC
LIMIT 10
