/* Tag popularity: number of distinct posts and distinct interested persons per tag, plus the ratio of posts per interested person */
WITH tag_agg AS (
    SELECT
        t.id,
        t.name,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        COUNT(DISTINCT p.person_id) AS person_cnt
    FROM tag t
    LEFT JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    LEFT JOIN person_has_interest_tag p
        ON p.tag_id = t.id
    GROUP BY t.id, t.name
)
SELECT
    id,
    name,
    post_cnt,
    person_cnt,
    CAST(post_cnt AS double) / NULLIF(person_cnt, 0) AS posts_per_person
FROM tag_agg
ORDER BY post_cnt DESC
LIMIT 20
