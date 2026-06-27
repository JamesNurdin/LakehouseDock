WITH tag_stats AS (
    SELECT
        o.name AS university_name,
        t.name AS tag_name,
        COUNT(DISTINCT po.id) AS post_count,
        COUNT(plp.person_id) AS like_count,
        AVG(po.length) AS avg_post_length
    FROM organisation o
    JOIN person_study_at_university psu
        ON psu.university_id = o.id
    JOIN person p
        ON psu.person_id = p.id
    JOIN post po
        ON po.creator_person_id = p.id
    JOIN post_has_tag_tag pht
        ON pht.post_id = po.id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
        AND pit.tag_id = t.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = po.id
    GROUP BY
        o.name,
        t.name
)
SELECT
    university_name,
    tag_name,
    post_count,
    like_count,
    avg_post_length
FROM (
    SELECT
        university_name,
        tag_name,
        post_count,
        like_count,
        avg_post_length,
        ROW_NUMBER() OVER (PARTITION BY university_name ORDER BY like_count DESC) AS rn
    FROM tag_stats
) ranked_tags
WHERE rn <= 5
ORDER BY university_name, like_count DESC
