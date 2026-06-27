WITH
    emp_counts AS (
        SELECT pwc.company_id,
               COUNT(DISTINCT pwc.person_id) AS employee_cnt
        FROM person_work_at_company pwc
        GROUP BY pwc.company_id
    ),
    post_stats AS (
        SELECT pwc.company_id,
               COUNT(DISTINCT po.id) AS total_posts,
               COUNT(plp.person_id) AS total_post_likes
        FROM person_work_at_company pwc
        JOIN person p ON pwc.person_id = p.id
        JOIN post po ON po.creator_person_id = p.id
        LEFT JOIN person_likes_post plp ON plp.post_id = po.id
        GROUP BY pwc.company_id
    ),
    comment_stats AS (
        SELECT pwc.company_id,
               COUNT(DISTINCT co.id) AS total_comments,
               COUNT(plc.person_id) AS total_comment_likes
        FROM person_work_at_company pwc
        JOIN person p ON pwc.person_id = p.id
        JOIN comment co ON co.creator_person_id = p.id
        LEFT JOIN person_likes_comment plc ON plc.comment_id = co.id
        GROUP BY pwc.company_id
    )
SELECT
    o.id AS company_id,
    o.name AS company_name,
    o.type AS company_type,
    COALESCE(ec.employee_cnt, 0) AS employee_cnt,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(ps.total_post_likes, 0) AS total_post_likes,
    COALESCE(cs.total_comments, 0) AS total_comments,
    COALESCE(cs.total_comment_likes, 0) AS total_comment_likes
FROM organisation o
LEFT JOIN emp_counts ec      ON ec.company_id = o.id
LEFT JOIN post_stats ps      ON ps.company_id = o.id
LEFT JOIN comment_stats cs   ON cs.company_id = o.id
WHERE o.type = 'Company'
ORDER BY total_post_likes DESC
LIMIT 10
