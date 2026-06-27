WITH employee_posts AS (
    SELECT
        pwc.company_id,
        po.id AS post_id,
        po.length AS post_length,
        po.creator_person_id AS creator_id
    FROM person_work_at_company pwc
    JOIN person p_creator
      ON pwc.person_id = p_creator.id
    JOIN post po
      ON po.creator_person_id = p_creator.id
),
post_likes AS (
    SELECT
        ep.company_id,
        plp.post_id,
        plp.person_id AS liker_id,
        p_liker.gender AS liker_gender
    FROM employee_posts ep
    JOIN person_likes_post plp
      ON plp.post_id = ep.post_id
    JOIN person p_liker
      ON plp.person_id = p_liker.id
)
SELECT
    pl.company_id,
    pl.liker_gender,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT pl.post_id) AS distinct_posts_liked,
    AVG(ep.post_length) AS avg_post_length
FROM post_likes pl
JOIN employee_posts ep
  ON pl.company_id = ep.company_id
 AND pl.post_id = ep.post_id
GROUP BY pl.company_id, pl.liker_gender
ORDER BY total_likes DESC
LIMIT 100
