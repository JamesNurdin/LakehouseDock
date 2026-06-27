WITH employee_counts AS (
    SELECT
        org.id AS organisation_id,
        COUNT(DISTINCT p.id) AS employee_count
    FROM organisation org
    JOIN person_work_at_company pwc
        ON pwc.company_id = org.id
    JOIN person p
        ON p.id = pwc.person_id
    GROUP BY org.id
),
post_aggregates AS (
    SELECT
        org.id AS organisation_id,
        COUNT(DISTINCT post.id) AS post_count,
        SUM(post.length) AS total_post_length
    FROM organisation org
    JOIN person_work_at_company pwc
        ON pwc.company_id = org.id
    JOIN person p
        ON p.id = pwc.person_id
    JOIN post
        ON post.creator_person_id = p.id
    GROUP BY org.id
),
tag_counts AS (
    SELECT
        org.id AS organisation_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_tag_count
    FROM organisation org
    JOIN person_work_at_company pwc
        ON pwc.company_id = org.id
    JOIN person p
        ON p.id = pwc.person_id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    GROUP BY org.id
),
forum_counts AS (
    SELECT
        org.id AS organisation_id,
        COUNT(DISTINCT fmp.forum_id) AS distinct_forum_count
    FROM organisation org
    JOIN person_work_at_company pwc
        ON pwc.company_id = org.id
    JOIN person p
        ON p.id = pwc.person_id
    JOIN forum_has_member_person fmp
        ON fmp.person_id = p.id
    GROUP BY org.id
)
SELECT
    org.id AS organisation_id,
    org.type AS organisation_type,
    org.name AS organisation_name,
    COALESCE(ec.employee_count, 0) AS employee_count,
    COALESCE(ps.post_count, 0) AS post_count,
    CASE WHEN COALESCE(ps.post_count, 0) > 0
         THEN ps.total_post_length / ps.post_count
         ELSE NULL
    END AS avg_post_length,
    COALESCE(tc.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(fc.distinct_forum_count, 0) AS distinct_forum_count
FROM organisation org
LEFT JOIN employee_counts ec
    ON ec.organisation_id = org.id
LEFT JOIN post_aggregates ps
    ON ps.organisation_id = org.id
LEFT JOIN tag_counts tc
    ON tc.organisation_id = org.id
LEFT JOIN forum_counts fc
    ON fc.organisation_id = org.id
ORDER BY employee_count DESC
LIMIT 10
