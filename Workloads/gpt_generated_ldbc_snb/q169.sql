WITH
    person_posts AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT po.id) AS post_count,
            COALESCE(SUM(po.length), 0) AS total_post_length,
            COALESCE(AVG(po.length), 0) AS avg_post_length
        FROM person p
        LEFT JOIN post po
            ON po.creator_person_id = p.id
        GROUP BY p.id
    ),
    person_comments AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT c.id) AS comment_count
        FROM person p
        LEFT JOIN comment c
            ON c.creator_person_id = p.id
        GROUP BY p.id
    ),
    person_likes_given AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT plp.post_id) AS likes_given
        FROM person p
        LEFT JOIN person_likes_post plp
            ON plp.person_id = p.id
        GROUP BY p.id
    ),
    person_likes_received AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT plp2.person_id) AS likes_received
        FROM person p
        LEFT JOIN post po
            ON po.creator_person_id = p.id
        LEFT JOIN person_likes_post plp2
            ON plp2.post_id = po.id
        GROUP BY p.id
    ),
    friend_links AS (
        SELECT pkp.person1_id AS person_id, pkp.person2_id AS friend_id
        FROM person_knows_person pkp
        UNION ALL
        SELECT pkp.person2_id AS person_id, pkp.person1_id AS friend_id
        FROM person_knows_person pkp
    ),
    person_friends AS (
        SELECT
            fl.person_id,
            COUNT(DISTINCT fl.friend_id) AS friend_count
        FROM friend_links fl
        GROUP BY fl.person_id
    ),
    person_company AS (
        SELECT
            p.id AS person_id,
            org.name AS company_name
        FROM person p
        JOIN person_work_at_company pwac
            ON pwac.person_id = p.id
        JOIN organisation org
            ON org.id = pwac.company_id
        WHERE org.name = 'Acme Corp'
    )
SELECT
    pc.person_id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(pp.post_count, 0) AS post_count,
    COALESCE(pcmt.comment_count, 0) AS comment_count,
    COALESCE(plg.likes_given, 0) AS likes_given,
    COALESCE(plr.likes_received, 0) AS likes_received,
    COALESCE(pf.friend_count, 0) AS friend_count,
    pc.company_name,
    COALESCE(pp.total_post_length, 0) AS total_post_length,
    COALESCE(pp.avg_post_length, 0) AS avg_post_length
FROM person_company pc
JOIN person p
    ON p.id = pc.person_id
LEFT JOIN person_posts pp
    ON pp.person_id = p.id
LEFT JOIN person_comments pcmt
    ON pcmt.person_id = p.id
LEFT JOIN person_likes_given plg
    ON plg.person_id = p.id
LEFT JOIN person_likes_received plr
    ON plr.person_id = p.id
LEFT JOIN person_friends pf
    ON pf.person_id = p.id
ORDER BY likes_received DESC
LIMIT 10
