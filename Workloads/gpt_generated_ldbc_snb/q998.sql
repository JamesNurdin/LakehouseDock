WITH member_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
post_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
likes_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS total_likes,
        COUNT(DISTINCT pl.person_id) AS distinct_likers
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
moderator_friends AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pk.person2_id) AS moderator_friends_count
    FROM forum f
    LEFT JOIN person moderator
        ON moderator.id = f.moderator_person_id
    LEFT JOIN person_knows_person pk
        ON pk.person1_id = moderator.id
    GROUP BY f.id
),
member_interests AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_member_tags,
        COUNT(pit.person_id) AS total_member_tags
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person p
        ON p.id = fm.person_id
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mc.member_count,
    pc.post_count,
    pc.avg_post_length,
    ls.total_likes,
    ls.distinct_likers,
    mf.moderator_friends_count,
    mi.distinct_member_tags,
    mi.total_member_tags
FROM forum f
LEFT JOIN member_counts mc
    ON mc.forum_id = f.id
LEFT JOIN post_counts pc
    ON pc.forum_id = f.id
LEFT JOIN likes_stats ls
    ON ls.forum_id = f.id
LEFT JOIN moderator_friends mf
    ON mf.forum_id = f.id
LEFT JOIN member_interests mi
    ON mi.forum_id = f.id
ORDER BY mc.member_count DESC NULLS LAST
LIMIT 10
