WITH
    post_counts AS (
        SELECT
            p.creator_person_id AS person_id,
            COUNT(*) AS post_count
        FROM post p
        GROUP BY p.creator_person_id
    ),
    comment_counts AS (
        SELECT
            c.creator_person_id AS person_id,
            COUNT(*) AS comment_count
        FROM comment c
        GROUP BY c.creator_person_id
    ),
    likes_given_posts AS (
        SELECT
            plp.person_id,
            COUNT(*) AS likes_given_posts
        FROM person_likes_post plp
        GROUP BY plp.person_id
    ),
    likes_given_comments AS (
        SELECT
            plc.person_id,
            COUNT(*) AS likes_given_comments
        FROM person_likes_comment plc
        GROUP BY plc.person_id
    ),
    likes_received_posts AS (
        SELECT
            p.creator_person_id AS person_id,
            COUNT(*) AS likes_received_posts
        FROM post p
        JOIN person_likes_post plp
            ON p.id = plp.post_id
        GROUP BY p.creator_person_id
    ),
    likes_received_comments AS (
        SELECT
            c.creator_person_id AS person_id,
            COUNT(*) AS likes_received_comments
        FROM comment c
        JOIN person_likes_comment plc
            ON c.id = plc.comment_id
        GROUP BY c.creator_person_id
    ),
    friend_counts AS (
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
    interest_counts AS (
        SELECT
            pit.person_id,
            COUNT(DISTINCT pit.tag_id) AS interest_count
        FROM person_has_interest_tag pit
        GROUP BY pit.person_id
    ),
    work_counts AS (
        SELECT
            pwac.person_id,
            COUNT(DISTINCT pwac.company_id) AS work_count
        FROM person_work_at_company pwac
        GROUP BY pwac.person_id
    ),
    study_counts AS (
        SELECT
            psu.person_id,
            COUNT(DISTINCT psu.university_id) AS study_count
        FROM person_study_at_university psu
        GROUP BY psu.person_id
    )
SELECT
    per.id AS person_id,
    per.first_name,
    per.last_name,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(lgp.likes_given_posts, 0) + COALESCE(lgc.likes_given_comments, 0) AS likes_given_count,
    COALESCE(lrp.likes_received_posts, 0) + COALESCE(lrc.likes_received_comments, 0) AS likes_received_count,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(ic.interest_count, 0) AS interest_count,
    COALESCE(wc.work_count, 0) AS work_count,
    COALESCE(sc.study_count, 0) AS study_count,
    (COALESCE(pc.post_count, 0) +
     COALESCE(cc.comment_count, 0) +
     COALESCE(lgp.likes_given_posts, 0) + COALESCE(lgc.likes_given_comments, 0) +
     COALESCE(lrp.likes_received_posts, 0) + COALESCE(lrc.likes_received_comments, 0) +
     COALESCE(fc.friend_count, 0) +
     COALESCE(ic.interest_count, 0) +
     COALESCE(wc.work_count, 0) +
     COALESCE(sc.study_count, 0)
    ) AS total_activity_score
FROM person per
LEFT JOIN post_counts pc ON per.id = pc.person_id
LEFT JOIN comment_counts cc ON per.id = cc.person_id
LEFT JOIN likes_given_posts lgp ON per.id = lgp.person_id
LEFT JOIN likes_given_comments lgc ON per.id = lgc.person_id
LEFT JOIN likes_received_posts lrp ON per.id = lrp.person_id
LEFT JOIN likes_received_comments lrc ON per.id = lrc.person_id
LEFT JOIN friend_counts fc ON per.id = fc.person_id
LEFT JOIN interest_counts ic ON per.id = ic.person_id
LEFT JOIN work_counts wc ON per.id = wc.person_id
LEFT JOIN study_counts sc ON per.id = sc.person_id
ORDER BY total_activity_score DESC
LIMIT 10
