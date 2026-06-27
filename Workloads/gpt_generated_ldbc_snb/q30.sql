WITH
    forum_posts AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT p.id) AS post_count,
            AVG(p.length) AS avg_post_length,
            SUM(COALESCE(plp_like_cnt.like_cnt, 0)) AS total_post_likes
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN (
            SELECT plp.post_id, COUNT(*) AS like_cnt
            FROM person_likes_post plp
            GROUP BY plp.post_id
        ) plp_like_cnt
            ON plp_like_cnt.post_id = p.id
        GROUP BY f.id
    ),
    forum_comments AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT c.id) AS comment_count,
            AVG(c.length) AS avg_comment_length,
            SUM(COALESCE(plc_like_cnt.like_cnt, 0)) AS total_comment_likes
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
        LEFT JOIN (
            SELECT plc.comment_id, COUNT(*) AS like_cnt
            FROM person_likes_comment plc
            GROUP BY plc.comment_id
        ) plc_like_cnt
            ON plc_like_cnt.comment_id = c.id
        GROUP BY f.id
    ),
    forum_members AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum f
        LEFT JOIN forum_has_member_person fm
            ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    forum_tags AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT ft.tag_id) AS tag_count
        FROM forum f
        LEFT JOIN forum_has_tag_tag ft
            ON ft.forum_id = f.id
        GROUP BY f.id
    )
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fp.total_post_likes, 0) AS total_post_likes,
    COALESCE(fc.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(ft.tag_count, 0) AS tag_count,
    (COALESCE(fp.total_post_likes, 0) + COALESCE(fc.total_comment_likes, 0)) AS total_likes
FROM forum f
LEFT JOIN forum_posts fp   ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_members fm  ON fm.forum_id = f.id
LEFT JOIN forum_tags ft     ON ft.forum_id = f.id
ORDER BY total_likes DESC
LIMIT 10
