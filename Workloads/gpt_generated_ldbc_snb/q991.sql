WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        fm.person_id AS member_person_id
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
),
member_details AS (
    SELECT
        fm.forum_id,
        fm.forum_title,
        fm.member_person_id,
        p.id AS person_id
    FROM forum_members fm
    JOIN person p
        ON p.id = fm.member_person_id   -- person.id = forum_has_member_person.person_id
),
forum_member_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT member_person_id) AS member_count
    FROM forum_members
    GROUP BY forum_id
),
member_comments AS (
    SELECT
        md.forum_id,
        AVG(c.length) AS avg_comment_length,
        COUNT(*) AS comment_count
    FROM member_details md
    JOIN comment c
        ON c.creator_person_id = md.person_id   -- comment.creator_person_id = person.id
    GROUP BY md.forum_id
),
member_interests AS (
    SELECT
        md.forum_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_interest_tag_count
    FROM member_details md
    JOIN person_has_interest_tag pit
        ON pit.person_id = md.person_id   -- person_has_interest_tag.person_id = person.id
    GROUP BY md.forum_id
),
member_likes AS (
    SELECT
        md.forum_id,
        COUNT(*) AS total_likes_by_members
    FROM member_details md
    JOIN person_likes_post plp
        ON plp.person_id = md.person_id   -- person_likes_post.person_id = person.id
    GROUP BY md.forum_id
),
member_friendships AS (
    SELECT
        md1.forum_id,
        COUNT(*) AS friendship_count
    FROM member_details md1
    JOIN person_knows_person pkp
        ON pkp.person1_id = md1.person_id   -- person_knows_person.person1_id = person.id
    JOIN member_details md2
        ON md2.forum_id = md1.forum_id
        AND md2.person_id = pkp.person2_id   -- person_knows_person.person2_id = person.id
    GROUP BY md1.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fmc.member_count, 0) AS member_count,
    COALESCE(mc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(mc.comment_count, 0) AS comment_count,
    COALESCE(mi.distinct_interest_tag_count, 0) AS distinct_interest_tag_count,
    COALESCE(mf.friendship_count, 0) AS friendship_count,
    COALESCE(ml.total_likes_by_members, 0) AS total_likes_by_members
FROM forum f
LEFT JOIN forum_member_counts fmc
    ON fmc.forum_id = f.id
LEFT JOIN member_comments mc
    ON mc.forum_id = f.id
LEFT JOIN member_interests mi
    ON mi.forum_id = f.id
LEFT JOIN member_friendships mf
    ON mf.forum_id = f.id
LEFT JOIN member_likes ml
    ON ml.forum_id = f.id
ORDER BY f.id
