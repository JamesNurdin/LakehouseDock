WITH person_analytics AS (
    SELECT
        per.id AS person_id,
        per.first_name,
        per.last_name,
        per.gender,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT t.id) AS distinct_post_tag_count,
        COUNT(DISTINCT pkp.person2_id) AS friend_count,
        COUNT(DISTINCT pit.tag_id) AS interest_tag_count,
        COUNT(DISTINCT pwac.company_id) AS company_count
    FROM person per
    LEFT JOIN post p
        ON p.creator_person_id = per.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    LEFT JOIN tag t
        ON t.id = pht.tag_id
    LEFT JOIN person_knows_person pkp
        ON pkp.person1_id = per.id
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = per.id
    LEFT JOIN person_work_at_company pwac
        ON pwac.person_id = per.id
    GROUP BY per.id, per.first_name, per.last_name, per.gender
)
SELECT
    person_id,
    first_name,
    last_name,
    gender,
    post_count,
    avg_post_length,
    distinct_post_tag_count,
    friend_count,
    interest_tag_count,
    company_count
FROM person_analytics
ORDER BY post_count DESC
LIMIT 20
