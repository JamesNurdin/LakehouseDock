WITH tag_class_hierarchy AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COALESCE(parent_tc.name, 'Root') AS parent_class_name
    FROM tag_class tc
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
)
SELECT
    tch.tag_class_name,
    COUNT(DISTINCT p.id) AS distinct_persons_interested,
    COUNT(DISTINCT ch.comment_id) AS distinct_comments_tagged,
    COUNT(DISTINCT ph.post_id) AS distinct_posts_tagged,
    COUNT(DISTINCT fh.forum_id) AS distinct_forums_tagged,
    AVG(pwc.work_from) AS avg_work_from_years
FROM tag_class_hierarchy tch
LEFT JOIN tag t
    ON t.type_tag_class_id = tch.tag_class_id
LEFT JOIN person_has_interest_tag phi
    ON phi.tag_id = t.id
LEFT JOIN person p
    ON phi.person_id = p.id
LEFT JOIN person_work_at_company pwc
    ON pwc.person_id = p.id
LEFT JOIN comment_has_tag_tag ch
    ON ch.tag_id = t.id
LEFT JOIN post_has_tag_tag ph
    ON ph.tag_id = t.id
LEFT JOIN forum_has_tag_tag fh
    ON fh.tag_id = t.id
GROUP BY tch.tag_class_name
ORDER BY distinct_persons_interested DESC
LIMIT 10
