WITH
    tag_counts AS (
        SELECT
            tag_class.id AS tag_class_id,
            COUNT(DISTINCT tag.id) AS tag_cnt
        FROM tag
        JOIN tag_class
            ON tag.type_tag_class_id = tag_class.id
        GROUP BY tag_class.id
    ),
    forum_counts AS (
        SELECT
            tag_class.id AS tag_class_id,
            COUNT(DISTINCT forum_has_tag_tag.forum_id) AS forum_cnt
        FROM forum_has_tag_tag
        JOIN tag
            ON forum_has_tag_tag.tag_id = tag.id
        JOIN tag_class
            ON tag.type_tag_class_id = tag_class.id
        GROUP BY tag_class.id
    ),
    person_interest_counts AS (
        SELECT
            tag_class.id AS tag_class_id,
            COUNT(DISTINCT person.id) AS person_cnt
        FROM person_has_interest_tag
        JOIN person
            ON person_has_interest_tag.person_id = person.id
        JOIN tag
            ON person_has_interest_tag.tag_id = tag.id
        JOIN tag_class
            ON tag.type_tag_class_id = tag_class.id
        GROUP BY tag_class.id
    ),
    company_counts AS (
        SELECT
            tag_class.id AS tag_class_id,
            COUNT(DISTINCT person_work_at_company.company_id) AS company_cnt
        FROM person_has_interest_tag
        JOIN person
            ON person_has_interest_tag.person_id = person.id
        JOIN tag
            ON person_has_interest_tag.tag_id = tag.id
        JOIN tag_class
            ON tag.type_tag_class_id = tag_class.id
        JOIN person_work_at_company
            ON person.id = person_work_at_company.person_id
        GROUP BY tag_class.id
    ),
    place_counts AS (
        SELECT
            tag_class.id AS tag_class_id,
            COUNT(DISTINCT place.id) AS place_cnt
        FROM person_has_interest_tag
        JOIN person
            ON person_has_interest_tag.person_id = person.id
        JOIN tag
            ON person_has_interest_tag.tag_id = tag.id
        JOIN tag_class
            ON tag.type_tag_class_id = tag_class.id
        JOIN place
            ON person.location_city_id = place.id
        GROUP BY tag_class.id
    )
SELECT
    tag_class.id,
    tag_class.name,
    COALESCE(tag_counts.tag_cnt, 0) AS tag_count,
    COALESCE(forum_counts.forum_cnt, 0) AS forum_count,
    COALESCE(person_interest_counts.person_cnt, 0) AS person_interest_count,
    COALESCE(company_counts.company_cnt, 0) AS company_count,
    COALESCE(place_counts.place_cnt, 0) AS place_count
FROM tag_class
LEFT JOIN tag_counts
    ON tag_class.id = tag_counts.tag_class_id
LEFT JOIN forum_counts
    ON tag_class.id = forum_counts.tag_class_id
LEFT JOIN person_interest_counts
    ON tag_class.id = person_interest_counts.tag_class_id
LEFT JOIN company_counts
    ON tag_class.id = company_counts.tag_class_id
LEFT JOIN place_counts
    ON tag_class.id = place_counts.tag_class_id
ORDER BY tag_class.id
