WITH person_base AS (
    SELECT
        id AS person_id,
        first_name,
        last_name,
        gender,
        location_city_id
    FROM person
),
person_city AS (
    SELECT
        p.person_id,
        pl.name AS city_name
    FROM person_base p
    LEFT JOIN place pl
        ON p.location_city_id = pl.id
),
comment_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS total_comments_created,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
comment_country_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT c.location_country_id) AS distinct_comment_countries,
        ARRAY_AGG(DISTINCT pl.name) AS comment_country_names
    FROM comment c
    LEFT JOIN place pl
        ON c.location_country_id = pl.id
    GROUP BY c.creator_person_id
),
likes_given_stats AS (
    SELECT
        person_id,
        COUNT(*) AS total_likes_given
    FROM person_likes_comment
    GROUP BY person_id
),
likes_received_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS total_likes_received
    FROM comment c
    JOIN person_likes_comment plc
        ON c.id = plc.comment_id
    GROUP BY c.creator_person_id
),
tag_stats AS (
    SELECT
        person_id,
        COUNT(DISTINCT tag_id) AS distinct_tags
    FROM person_has_interest_tag
    GROUP BY person_id
),
forum_stats AS (
    SELECT
        person_id,
        COUNT(DISTINCT forum_id) AS distinct_forums
    FROM forum_has_member_person
    GROUP BY person_id
)
SELECT
    p.person_id,
    p.first_name,
    p.last_name,
    p.gender,
    pc.city_name,
    COALESCE(cs.total_comments_created, 0) AS total_comments_created,
    cs.avg_comment_length,
    COALESCE(lg.total_likes_given, 0) AS total_likes_given,
    COALESCE(lr.total_likes_received, 0) AS total_likes_received,
    COALESCE(ts.distinct_tags, 0) AS distinct_tags,
    COALESCE(fs.distinct_forums, 0) AS distinct_forums,
    COALESCE(ccs.distinct_comment_countries, 0) AS distinct_comment_countries,
    ccs.comment_country_names
FROM person_base p
LEFT JOIN person_city pc
    ON p.person_id = pc.person_id
LEFT JOIN comment_stats cs
    ON p.person_id = cs.person_id
LEFT JOIN comment_country_stats ccs
    ON p.person_id = ccs.person_id
LEFT JOIN likes_given_stats lg
    ON p.person_id = lg.person_id
LEFT JOIN likes_received_stats lr
    ON p.person_id = lr.person_id
LEFT JOIN tag_stats ts
    ON p.person_id = ts.person_id
LEFT JOIN forum_stats fs
    ON p.person_id = fs.person_id
ORDER BY total_comments_created DESC
LIMIT 100
