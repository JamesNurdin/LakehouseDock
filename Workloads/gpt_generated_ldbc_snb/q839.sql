WITH employee_comments AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id,
        c.parent_post_id,
        p.id AS post_id,
        f.id AS forum_id,
        f.title AS forum_title,
        org.id AS company_id,
        pl.name AS company_country
    FROM comment c
    JOIN person p_creator
        ON c.creator_person_id = p_creator.id
    JOIN person_work_at_company pwc
        ON p_creator.id = pwc.person_id
    JOIN organisation org
        ON pwc.company_id = org.id
    JOIN place pl
        ON org.location_place_id = pl.id
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN forum f
        ON p.container_forum_id = f.id
),
comment_likes AS (
    SELECT
        cl.comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment cl
    GROUP BY cl.comment_id
),
forum_members AS (
    SELECT
        fmp.forum_id,
        COUNT(DISTINCT fmp.person_id) AS member_cnt
    FROM forum_has_member_person fmp
    GROUP BY fmp.forum_id
)
SELECT
    ec.company_country,
    ec.forum_title,
    COUNT(DISTINCT ec.comment_id) AS comment_cnt,
    AVG(ec.comment_length) AS avg_comment_len,
    SUM(COALESCE(cl.like_count, 0)) AS total_likes,
    COUNT(DISTINCT ec.creator_person_id) AS distinct_commenters,
    fm.member_cnt
FROM employee_comments ec
LEFT JOIN comment_likes cl
    ON ec.comment_id = cl.comment_id
JOIN forum_members fm
    ON ec.forum_id = fm.forum_id
WHERE ec.comment_length > 0
GROUP BY ec.company_country, ec.forum_title, fm.member_cnt
ORDER BY comment_cnt DESC
LIMIT 100
