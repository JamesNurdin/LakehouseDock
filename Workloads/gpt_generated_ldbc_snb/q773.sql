WITH
    person_basic AS (
        SELECT
            id AS person_id,
            first_name,
            last_name,
            gender,
            birthday
        FROM person
    ),
    friend_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT friend_id) AS num_friends
        FROM (
            SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
            UNION ALL
            SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
        ) f
        GROUP BY person_id
    ),
    post_counts AS (
        SELECT
            creator_person_id AS person_id,
            COUNT(*) AS num_posts,
            COALESCE(SUM(length), 0) AS total_post_length,
            AVG(length) AS avg_post_length
        FROM post
        GROUP BY creator_person_id
    ),
    likes_given_posts AS (
        SELECT
            person_id,
            COUNT(*) AS likes_given_posts
        FROM person_likes_post
        GROUP BY person_id
    ),
    likes_received_posts AS (
        SELECT
            po.creator_person_id AS person_id,
            COUNT(pl.person_id) AS likes_received_posts
        FROM post po
        LEFT JOIN person_likes_post pl
            ON pl.post_id = po.id
        GROUP BY po.creator_person_id
    ),
    comment_counts AS (
        SELECT
            creator_person_id AS person_id,
            COUNT(*) AS num_comments,
            COALESCE(SUM(length), 0) AS total_comment_length,
            AVG(length) AS avg_comment_length
        FROM comment
        GROUP BY creator_person_id
    ),
    likes_given_comments AS (
        SELECT
            person_id,
            COUNT(*) AS likes_given_comments
        FROM person_likes_comment
        GROUP BY person_id
    ),
    likes_received_comments AS (
        SELECT
            c.creator_person_id AS person_id,
            COUNT(pcl.person_id) AS likes_received_comments
        FROM comment c
        LEFT JOIN person_likes_comment pcl
            ON pcl.comment_id = c.id
        GROUP BY c.creator_person_id
    ),
    forum_membership AS (
        SELECT
            person_id,
            COUNT(DISTINCT forum_id) AS num_forums_member
        FROM forum_has_member_person
        GROUP BY person_id
    ),
    forum_moderated AS (
        SELECT
            moderator_person_id AS person_id,
            COUNT(DISTINCT id) AS num_forums_moderated
        FROM forum
        GROUP BY moderator_person_id
    ),
    interest_tags AS (
        SELECT
            person_id,
            COUNT(DISTINCT tag_id) AS num_interests
        FROM person_has_interest_tag
        GROUP BY person_id
    )
SELECT
    pb.person_id,
    pb.first_name,
    pb.last_name,
    pb.gender,
    pb.birthday,
    COALESCE(fc.num_friends, 0) AS num_friends,
    COALESCE(pc.num_posts, 0) AS num_posts,
    COALESCE(pc.total_post_length, 0) AS total_post_length,
    COALESCE(pc.avg_post_length, 0) AS avg_post_length,
    COALESCE(lgp.likes_given_posts, 0) AS likes_given_posts,
    COALESCE(lrp.likes_received_posts, 0) AS likes_received_posts,
    COALESCE(cc.num_comments, 0) AS num_comments,
    COALESCE(cc.total_comment_length, 0) AS total_comment_length,
    COALESCE(cc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lgc.likes_given_comments, 0) AS likes_given_comments,
    COALESCE(lrc.likes_received_comments, 0) AS likes_received_comments,
    COALESCE(fm.num_forums_member, 0) AS num_forums_member,
    COALESCE(fmod.num_forums_moderated, 0) AS num_forums_moderated,
    COALESCE(it.num_interests, 0) AS num_interests,
    (
        COALESCE(pc.num_posts, 0) * 1.0
        + COALESCE(cc.num_comments, 0) * 1.0
        + COALESCE(lgp.likes_given_posts, 0) * 0.5
        + COALESCE(lgc.likes_given_comments, 0) * 0.5
        + COALESCE(lrp.likes_received_posts, 0) * 0.2
        + COALESCE(lrc.likes_received_comments, 0) * 0.2
        + COALESCE(fc.num_friends, 0) * 2.0
        + COALESCE(fm.num_forums_member, 0) * 1.0
        + COALESCE(fmod.num_forums_moderated, 0) * 2.0
        + COALESCE(it.num_interests, 0) * 0.5
    ) AS total_activity_score
FROM person_basic pb
LEFT JOIN friend_counts fc ON fc.person_id = pb.person_id
LEFT JOIN post_counts pc ON pc.person_id = pb.person_id
LEFT JOIN likes_given_posts lgp ON lgp.person_id = pb.person_id
LEFT JOIN likes_received_posts lrp ON lrp.person_id = pb.person_id
LEFT JOIN comment_counts cc ON cc.person_id = pb.person_id
LEFT JOIN likes_given_comments lgc ON lgc.person_id = pb.person_id
LEFT JOIN likes_received_comments lrc ON lrc.person_id = pb.person_id
LEFT JOIN forum_membership fm ON fm.person_id = pb.person_id
LEFT JOIN forum_moderated fmod ON fmod.person_id = pb.person_id
LEFT JOIN interest_tags it ON it.person_id = pb.person_id
ORDER BY total_activity_score DESC
LIMIT 20
