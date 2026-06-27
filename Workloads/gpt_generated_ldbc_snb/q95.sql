WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.gender AS moderator_gender
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
),
member_info AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT pwc.company_id) AS distinct_member_companies
    FROM forum_has_member_person fm
    LEFT JOIN person mem
        ON fm.person_id = mem.id
    LEFT JOIN person_work_at_company pwc
        ON pwc.person_id = mem.id
    GROUP BY fm.forum_id
),
moderator_friends AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pk.person2_id) AS moderator_friend_count
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN person_knows_person pk
        ON pk.person1_id = mod.id
    GROUP BY f.id
),
post_info AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.length), 0) AS total_post_length,
        CASE WHEN COUNT(DISTINCT p.id) > 0 THEN AVG(p.length) END AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_info AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
likes_info AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT plp.person_id) AS distinct_like_persons
    FROM person_likes_post plp
    JOIN post p
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fi.forum_id,
    fi.forum_title,
    fi.moderator_gender,
    COALESCE(mi.member_count, 0) AS member_count,
    COALESCE(mi.distinct_member_companies, 0) AS distinct_member_companies,
    COALESCE(pi.post_count, 0) AS post_count,
    pi.total_post_length,
    pi.avg_post_length,
    COALESCE(ci.comment_count, 0) AS comment_count,
    COALESCE(li.total_likes, 0) AS total_likes,
    COALESCE(li.distinct_like_persons, 0) AS distinct_like_persons,
    COALESCE(mf.moderator_friend_count, 0) AS moderator_friend_count,
    CASE WHEN COALESCE(pi.post_count, 0) > 0 THEN COALESCE(li.total_likes, 0) / pi.post_count ELSE 0 END AS avg_likes_per_post,
    CASE WHEN COALESCE(pi.post_count, 0) > 0 THEN COALESCE(ci.comment_count, 0) / pi.post_count ELSE 0 END AS avg_comments_per_post
FROM forum_info fi
LEFT JOIN member_info mi
    ON fi.forum_id = mi.forum_id
LEFT JOIN moderator_friends mf
    ON fi.forum_id = mf.forum_id
LEFT JOIN post_info pi
    ON fi.forum_id = pi.forum_id
LEFT JOIN comment_info ci
    ON fi.forum_id = ci.forum_id
LEFT JOIN likes_info li
    ON fi.forum_id = li.forum_id
ORDER BY fi.forum_id
