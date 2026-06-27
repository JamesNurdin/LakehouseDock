WITH
    posts_created AS (
        SELECT creator_person_id AS person_id,
               count(*) AS posts_created
        FROM post
        GROUP BY creator_person_id
    ),
    comments_created AS (
        SELECT creator_person_id AS person_id,
               count(*) AS comments_created
        FROM comment
        GROUP BY creator_person_id
    ),
    likes_given AS (
        SELECT person_id,
               count(*) AS likes_given
        FROM (
            SELECT person_id FROM person_likes_comment
            UNION ALL
            SELECT person_id FROM person_likes_post
        ) t
        GROUP BY person_id
    ),
    likes_received AS (
        SELECT creator_person_id AS person_id,
               count(*) AS likes_received
        FROM (
            SELECT c.creator_person_id
            FROM comment c
            JOIN person_likes_comment plc ON c.id = plc.comment_id
            UNION ALL
            SELECT po.creator_person_id
            FROM post po
            JOIN person_likes_post plp ON po.id = plp.post_id
        ) t
        GROUP BY creator_person_id
    ),
    interest_tags AS (
        SELECT person_id,
               count(DISTINCT tag_id) AS interest_tag_count
        FROM person_has_interest_tag
        GROUP BY person_id
    ),
    work_companies AS (
        SELECT person_id,
               count(DISTINCT company_id) AS company_count
        FROM person_work_at_company
        GROUP BY person_id
    ),
    moderated_forums AS (
        SELECT moderator_person_id AS person_id,
               count(*) AS forums_moderated
        FROM forum
        GROUP BY moderator_person_id
    ),
    member_forums AS (
        SELECT person_id,
               count(DISTINCT forum_id) AS forums_member_of
        FROM forum_has_member_person
        GROUP BY person_id
    )
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    city.name AS city_name,
    COALESCE(pc.posts_created, 0) AS posts_created,
    COALESCE(cc.comments_created, 0) AS comments_created,
    COALESCE(lg.likes_given, 0) AS likes_given,
    COALESCE(lr.likes_received, 0) AS likes_received,
    COALESCE(it.interest_tag_count, 0) AS interest_tag_count,
    COALESCE(wc.company_count, 0) AS company_count,
    COALESCE(mf.forums_moderated, 0) AS forums_moderated,
    COALESCE(mb.forums_member_of, 0) AS forums_member_of,
    CASE
        WHEN COALESCE(lg.likes_given, 0) = 0 THEN NULL
        ELSE CAST(COALESCE(lr.likes_received, 0) AS double) / COALESCE(lg.likes_given, 0)
    END AS like_efficiency
FROM person p
LEFT JOIN place city ON p.location_city_id = city.id
LEFT JOIN posts_created pc ON p.id = pc.person_id
LEFT JOIN comments_created cc ON p.id = cc.person_id
LEFT JOIN likes_given lg ON p.id = lg.person_id
LEFT JOIN likes_received lr ON p.id = lr.person_id
LEFT JOIN interest_tags it ON p.id = it.person_id
LEFT JOIN work_companies wc ON p.id = wc.person_id
LEFT JOIN moderated_forums mf ON p.id = mf.person_id
LEFT JOIN member_forums mb ON p.id = mb.person_id
ORDER BY likes_received DESC
LIMIT 20
