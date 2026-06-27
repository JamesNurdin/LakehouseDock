WITH member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
tag_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_tag_count
    FROM forum_has_member_person fm
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = fm.person_id
    GROUP BY fm.forum_id
),
liked_post_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT plp.post_id) AS distinct_liked_post_count
    FROM forum_has_member_person fm
    LEFT JOIN person_likes_post plp
        ON plp.person_id = fm.person_id
    GROUP BY fm.forum_id
),
friend_counts AS (
    SELECT
        fm.forum_id,
        fm.person_id,
        COUNT(DISTINCT pk.person2_id) AS friend_count
    FROM forum_has_member_person fm
    LEFT JOIN person_knows_person pk
        ON pk.person1_id = fm.person_id
    GROUP BY fm.forum_id, fm.person_id
),
avg_friend_counts AS (
    SELECT
        forum_id,
        AVG(friend_count) AS avg_friends_per_member
    FROM friend_counts
    GROUP BY forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(tc.distinct_tag_count, 0) AS distinct_member_tags,
    COALESCE(lpc.distinct_liked_post_count, 0) AS distinct_posts_liked_by_members,
    COALESCE(afc.avg_friends_per_member, 0) AS avg_friends_per_member
FROM forum f
LEFT JOIN person mod
    ON f.moderator_person_id = mod.id
LEFT JOIN member_counts mc
    ON mc.forum_id = f.id
LEFT JOIN tag_counts tc
    ON tc.forum_id = f.id
LEFT JOIN liked_post_counts lpc
    ON lpc.forum_id = f.id
LEFT JOIN avg_friend_counts afc
    ON afc.forum_id = f.id
ORDER BY member_count DESC
LIMIT 20
