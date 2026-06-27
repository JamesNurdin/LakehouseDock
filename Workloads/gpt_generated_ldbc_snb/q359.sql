/*
  Analytical query: per‑person activity summary across the social network.
  Shows basic profile information together with counts of friends, posts, comments,
  likes given/received, forum memberships, interests and distinct tags used in posts.
*/
WITH
    person_posts AS (
        SELECT
            p.id AS person_id,
            COUNT(*) AS post_count,
            SUM(pst.length) AS total_post_length
        FROM person p
        JOIN post pst ON pst.creator_person_id = p.id
        GROUP BY p.id
    ),
    person_comments AS (
        SELECT
            p.id AS person_id,
            COUNT(*) AS comment_count,
            SUM(cmt.length) AS total_comment_length
        FROM person p
        JOIN comment cmt ON cmt.creator_person_id = p.id
        GROUP BY p.id
    ),
    person_friends AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT pk.person2_id) AS friend_count
        FROM person p
        JOIN person_knows_person pk ON pk.person1_id = p.id
        GROUP BY p.id
    ),
    person_likes_given AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT plp.post_id) AS likes_given_on_posts,
            COUNT(DISTINCT plc.comment_id) AS likes_given_on_comments
        FROM person p
        LEFT JOIN person_likes_post plp ON plp.person_id = p.id
        LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
        GROUP BY p.id
    ),
    person_likes_received AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT plp.person_id) AS likes_received_on_posts,
            COUNT(DISTINCT plc.person_id) AS likes_received_on_comments
        FROM person p
        LEFT JOIN post pst ON pst.creator_person_id = p.id
        LEFT JOIN person_likes_post plp ON plp.post_id = pst.id
        LEFT JOIN comment cmt ON cmt.creator_person_id = p.id
        LEFT JOIN person_likes_comment plc ON plc.comment_id = cmt.id
        GROUP BY p.id
    ),
    person_forums AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT fmp.forum_id) AS forum_membership_count
        FROM person p
        JOIN forum_has_member_person fmp ON fmp.person_id = p.id
        GROUP BY p.id
    ),
    person_interests AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT pit.tag_id) AS interest_tag_count
        FROM person p
        JOIN person_has_interest_tag pit ON pit.person_id = p.id
        GROUP BY p.id
    ),
    person_post_tags AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT pht.tag_id) AS post_tag_count
        FROM person p
        JOIN post pst ON pst.creator_person_id = p.id
        JOIN post_has_tag_tag pht ON pht.post_id = pst.id
        GROUP BY p.id
    )
SELECT
    per.id,
    per.first_name,
    per.last_name,
    per.gender,
    per.birthday,
    per.email,
    COALESCE(pf.friend_count, 0) AS friend_count,
    COALESCE(pp.post_count, 0) AS post_count,
    COALESCE(pp.total_post_length, 0) AS total_post_length,
    COALESCE(pc.comment_count, 0) AS comment_count,
    COALESCE(pc.total_comment_length, 0) AS total_comment_length,
    COALESCE(plg.likes_given_on_posts, 0) + COALESCE(plg.likes_given_on_comments, 0) AS total_likes_given,
    COALESCE(plr.likes_received_on_posts, 0) + COALESCE(plr.likes_received_on_comments, 0) AS total_likes_received,
    COALESCE(pfmem.forum_membership_count, 0) AS forum_membership_count,
    COALESCE(pi.interest_tag_count, 0) AS interest_tag_count,
    COALESCE(ppt.post_tag_count, 0) AS post_tag_count
FROM person per
LEFT JOIN person_friends pf ON pf.person_id = per.id
LEFT JOIN person_posts pp ON pp.person_id = per.id
LEFT JOIN person_comments pc ON pc.person_id = per.id
LEFT JOIN person_likes_given plg ON plg.person_id = per.id
LEFT JOIN person_likes_received plr ON plr.person_id = per.id
LEFT JOIN person_forums pfmem ON pfmem.person_id = per.id
LEFT JOIN person_interests pi ON pi.person_id = per.id
LEFT JOIN person_post_tags ppt ON ppt.person_id = per.id
ORDER BY total_likes_received DESC
LIMIT 100
