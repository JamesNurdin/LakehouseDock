WITH
    forum_base AS (
        SELECT f.id AS forum_id,
               f.title AS forum_title
        FROM forum f
    ),
    member_counts AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    post_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT p.id) AS post_count
        FROM post p
        GROUP BY p.container_forum_id
    ),
    comment_stats AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT c.id) AS comment_count,
               AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p
          ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    post_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT plp.person_id) AS post_like_count
        FROM person_likes_post plp
        JOIN post p
          ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT plc.person_id) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c
          ON plc.comment_id = c.id
        JOIN post p
          ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    member_company_counts AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT org.id) AS member_company_count
        FROM forum_has_member_person fm
        JOIN person pw
          ON fm.person_id = pw.id
        JOIN person_work_at_company pwc
          ON pw.id = pwc.person_id
        JOIN organisation org
          ON pwc.company_id = org.id
          AND org.type = 'company'
        GROUP BY fm.forum_id
    ),
    member_university_counts AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT org.id) AS member_university_count
        FROM forum_has_member_person fm
        JOIN person pw
          ON fm.person_id = pw.id
        JOIN person_study_at_university psu
          ON pw.id = psu.person_id
        JOIN organisation org
          ON psu.university_id = org.id
          AND org.type = 'university'
        GROUP BY fm.forum_id
    )
SELECT
    fb.forum_id,
    fb.forum_title,
    COALESCE(mc.member_count, 0)               AS member_count,
    COALESCE(pc.post_count, 0)                 AS post_count,
    COALESCE(cs.comment_count, 0)              AS comment_count,
    cs.avg_comment_length,
    COALESCE(plc.post_like_count, 0)           AS post_like_count,
    COALESCE(clc.comment_like_count, 0)        AS comment_like_count,
    COALESCE(mcc.member_company_count, 0)     AS member_company_count,
    COALESCE(muc.member_university_count, 0)  AS member_university_count
FROM forum_base fb
LEFT JOIN member_counts mc
       ON fb.forum_id = mc.forum_id
LEFT JOIN post_counts pc
       ON fb.forum_id = pc.forum_id
LEFT JOIN comment_stats cs
       ON fb.forum_id = cs.forum_id
LEFT JOIN post_like_counts plc
       ON fb.forum_id = plc.forum_id
LEFT JOIN comment_like_counts clc
       ON fb.forum_id = clc.forum_id
LEFT JOIN member_company_counts mcc
       ON fb.forum_id = mcc.forum_id
LEFT JOIN member_university_counts muc
       ON fb.forum_id = muc.forum_id
ORDER BY post_count DESC
LIMIT 10
