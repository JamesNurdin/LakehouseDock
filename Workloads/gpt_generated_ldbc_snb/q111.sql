WITH creator_posts AS (
    SELECT
        pht.tag_id,
        pwc.company_id,
        post.id AS post_id,
        post.length AS post_length
    FROM person_has_interest_tag pht
    JOIN person p ON p.id = pht.person_id
    JOIN person_work_at_company pwc ON pwc.person_id = p.id
    JOIN post ON post.creator_person_id = p.id
    JOIN person_likes_post plp ON plp.post_id = post.id
)
SELECT
    tag_id,
    company_id,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT post_id) AS distinct_posts,
    AVG(post_length) AS avg_post_length
FROM creator_posts
GROUP BY tag_id, company_id
ORDER BY total_likes DESC
LIMIT 20
