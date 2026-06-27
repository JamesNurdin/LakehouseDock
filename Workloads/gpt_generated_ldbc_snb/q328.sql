WITH interested_persons AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        p.gender,
        p.birthday,
        p.location_city_id,
        p.email,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent_tc.id AS parent_tag_class_id,
        parent_tc.name AS parent_tag_class_name
    FROM person p
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    JOIN tag t
        ON pit.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
    JOIN person_study_at_university psu
        ON psu.person_id = p.id
)
SELECT
    ip.tag_name,
    ip.tag_class_name,
    ip.parent_tag_class_name,
    COUNT(DISTINCT ip.person_id) AS distinct_persons,
    COUNT(DISTINCT plp.post_id) AS distinct_posts_liked,
    COUNT(DISTINCT cht.comment_id) AS distinct_comments_tagged,
    COUNT(DISTINCT fht.forum_id) AS distinct_forums_tagged
FROM interested_persons ip
JOIN person_likes_post plp
    ON plp.person_id = ip.person_id
JOIN post_has_tag_tag pht
    ON pht.tag_id = ip.tag_id
LEFT JOIN comment_has_tag_tag cht
    ON cht.tag_id = ip.tag_id
LEFT JOIN forum_has_tag_tag fht
    ON fht.tag_id = ip.tag_id
GROUP BY
    ip.tag_name,
    ip.tag_class_name,
    ip.parent_tag_class_name
ORDER BY distinct_persons DESC
LIMIT 10
