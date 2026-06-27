WITH comment_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS total_comments,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
post_agg AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS total_posts
    FROM post p
    GROUP BY p.creator_person_id
),
friend_agg AS (
    SELECT
        pk.person_id,
        COUNT(DISTINCT pk.friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) pk
    GROUP BY pk.person_id
),
work_latest AS (
    SELECT
        pw.person_id,
        o.name AS company_name
    FROM (
        SELECT
            pw_inner.person_id,
            pw_inner.company_id,
            pw_inner.work_from,
            ROW_NUMBER() OVER (PARTITION BY pw_inner.person_id ORDER BY pw_inner.work_from DESC) AS rn
        FROM person_work_at_company pw_inner
    ) pw
    JOIN organisation o ON pw.company_id = o.id
    WHERE pw.rn = 1
),
education_latest AS (
    SELECT
        ps.person_id,
        o.name AS university_name
    FROM (
        SELECT
            ps_inner.person_id,
            ps_inner.university_id,
            ps_inner.class_year,
            ROW_NUMBER() OVER (PARTITION BY ps_inner.person_id ORDER BY ps_inner.class_year DESC) AS rn
        FROM person_study_at_university ps_inner
    ) ps
    JOIN organisation o ON ps.university_id = o.id
    WHERE ps.rn = 1
),
person_city AS (
    SELECT
        per.id AS person_id,
        per.first_name,
        per.last_name,
        per.gender,
        per.birthday,
        per.email,
        pl.id AS city_id,
        pl.name AS city_name
    FROM person per
    JOIN place pl ON per.location_city_id = pl.id
),
ranked_persons AS (
    SELECT
        pc.city_name,
        pc.city_id,
        pc.person_id,
        pc.first_name,
        pc.last_name,
        COALESCE(ca.total_comments, 0) AS total_comments,
        COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
        COALESCE(pa.total_posts, 0) AS total_posts,
        COALESCE(fa.friend_count, 0) AS friend_count,
        wl.company_name,
        el.university_name,
        ROW_NUMBER() OVER (PARTITION BY pc.city_id ORDER BY COALESCE(ca.total_comments, 0) DESC) AS rn
    FROM person_city pc
    LEFT JOIN comment_agg ca ON ca.person_id = pc.person_id
    LEFT JOIN post_agg pa ON pa.person_id = pc.person_id
    LEFT JOIN friend_agg fa ON fa.person_id = pc.person_id
    LEFT JOIN work_latest wl ON wl.person_id = pc.person_id
    LEFT JOIN education_latest el ON el.person_id = pc.person_id
)
SELECT
    city_name,
    person_id,
    first_name,
    last_name,
    total_comments,
    avg_comment_length,
    total_posts,
    friend_count,
    company_name,
    university_name
FROM ranked_persons
WHERE rn <= 5
ORDER BY city_name, total_comments DESC
