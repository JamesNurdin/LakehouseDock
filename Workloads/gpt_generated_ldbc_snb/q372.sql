WITH employee_counts AS (
    SELECT org.id AS organization_id,
           COUNT(DISTINCT pwac.person_id) AS employee_cnt
    FROM person_work_at_company pwac
    JOIN organisation org ON pwac.company_id = org.id
    GROUP BY org.id
),
posts_by_employee AS (
    SELECT org.id AS organization_id,
           p.id AS post_id
    FROM post p
    JOIN person per ON p.creator_person_id = per.id
    JOIN person_work_at_company pwac ON per.id = pwac.person_id
    JOIN organisation org ON pwac.company_id = org.id
),
comments_by_employee AS (
    SELECT org.id AS organization_id,
           c.id AS comment_id
    FROM comment c
    JOIN person per ON c.creator_person_id = per.id
    JOIN person_work_at_company pwac ON per.id = pwac.person_id
    JOIN organisation org ON pwac.company_id = org.id
),
post_counts AS (
    SELECT organization_id,
           COUNT(DISTINCT post_id) AS post_cnt
    FROM posts_by_employee
    GROUP BY organization_id
),
comment_counts AS (
    SELECT organization_id,
           COUNT(DISTINCT comment_id) AS comment_cnt
    FROM comments_by_employee
    GROUP BY organization_id
),
post_likes AS (
    SELECT pbe.organization_id,
           COUNT(plp.person_id) AS post_likes_cnt
    FROM posts_by_employee pbe
    JOIN person_likes_post plp ON plp.post_id = pbe.post_id
    GROUP BY pbe.organization_id
),
comment_likes AS (
    SELECT cbe.organization_id,
           COUNT(plc.person_id) AS comment_likes_cnt
    FROM comments_by_employee cbe
    JOIN person_likes_comment plc ON plc.comment_id = cbe.comment_id
    GROUP BY cbe.organization_id
),
post_tag_counts AS (
    SELECT pbe.organization_id,
           COUNT(DISTINCT pht.tag_id) AS distinct_post_tags
    FROM posts_by_employee pbe
    JOIN post_has_tag_tag pht ON pht.post_id = pbe.post_id
    GROUP BY pbe.organization_id
),
comment_tag_counts AS (
    SELECT cbe.organization_id,
           COUNT(DISTINCT cht.tag_id) AS distinct_comment_tags
    FROM comments_by_employee cbe
    JOIN comment_has_tag_tag cht ON cht.comment_id = cbe.comment_id
    GROUP BY cbe.organization_id
)
SELECT 
    org.id AS organization_id,
    org.name AS organization_name,
    COALESCE(ec.employee_cnt, 0) AS employee_cnt,
    COALESCE(pc.post_cnt, 0) AS post_cnt,
    COALESCE(cc.comment_cnt, 0) AS comment_cnt,
    COALESCE(pl.post_likes_cnt, 0) AS total_post_likes,
    COALESCE(cl.comment_likes_cnt, 0) AS total_comment_likes,
    COALESCE(ptc.distinct_post_tags, 0) AS distinct_post_tags,
    COALESCE(ctc.distinct_comment_tags, 0) AS distinct_comment_tags,
    CASE WHEN COALESCE(pc.post_cnt, 0) > 0 
         THEN COALESCE(pl.post_likes_cnt, 0) / CAST(pc.post_cnt AS double) 
         ELSE 0 END AS avg_likes_per_post,
    CASE WHEN COALESCE(cc.comment_cnt, 0) > 0 
         THEN COALESCE(cl.comment_likes_cnt, 0) / CAST(cc.comment_cnt AS double) 
         ELSE 0 END AS avg_likes_per_comment
FROM organisation org
LEFT JOIN employee_counts ec ON ec.organization_id = org.id
LEFT JOIN post_counts pc ON pc.organization_id = org.id
LEFT JOIN comment_counts cc ON cc.organization_id = org.id
LEFT JOIN post_likes pl ON pl.organization_id = org.id
LEFT JOIN comment_likes cl ON cl.organization_id = org.id
LEFT JOIN post_tag_counts ptc ON ptc.organization_id = org.id
LEFT JOIN comment_tag_counts ctc ON ctc.organization_id = org.id
ORDER BY total_post_likes DESC
LIMIT 20
