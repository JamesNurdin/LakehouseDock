SELECT
    f.id AS forum_id,
    f.title,
    moderator.first_name AS moderator_first_name,
    moderator.last_name AS moderator_last_name,
    COALESCE(p_agg.total_posts, 0) AS total_posts,
    COALESCE(p_agg.avg_post_length, 0) AS avg_post_length,
    COALESCE(m_agg.member_count, 0) AS distinct_member_count,
    COALESCE(t_agg.tag_count, 0) AS tag_count,
    COALESCE(k_agg.member_knowing_mod_count, 0) AS members_knowing_moderator,
    COALESCE(i_agg.members_with_matching_interest, 0) AS members_with_matching_interest
FROM forum f
LEFT JOIN person moderator
    ON f.moderator_person_id = moderator.id
-- Posts per forum and average post length
LEFT JOIN (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS total_posts,
        AVG(post.length) AS avg_post_length
    FROM post
    GROUP BY post.container_forum_id
) p_agg
    ON f.id = p_agg.forum_id
-- Distinct members per forum
LEFT JOIN (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
) m_agg
    ON f.id = m_agg.forum_id
-- Tag count per forum
LEFT JOIN (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS tag_count
    FROM forum_has_tag_tag
    GROUP BY forum_id
) t_agg
    ON f.id = t_agg.forum_id
-- Members who know the moderator (undirected friendship)
LEFT JOIN (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_knowing_mod_count
    FROM forum_has_member_person fm
    JOIN forum f2
        ON fm.forum_id = f2.id
    JOIN person_knows_person pk
        ON (pk.person1_id = f2.moderator_person_id AND pk.person2_id = fm.person_id)
        OR (pk.person2_id = f2.moderator_person_id AND pk.person1_id = fm.person_id)
    GROUP BY fm.forum_id
) k_agg
    ON f.id = k_agg.forum_id
-- Members whose interests intersect with forum tags
LEFT JOIN (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS members_with_matching_interest
    FROM forum_has_member_person fm
    JOIN person p
        ON fm.person_id = p.id
    JOIN person_has_interest_tag pi
        ON pi.person_id = p.id
    JOIN forum_has_tag_tag ft
        ON ft.forum_id = fm.forum_id AND ft.tag_id = pi.tag_id
    GROUP BY fm.forum_id
) i_agg
    ON f.id = i_agg.forum_id
ORDER BY total_posts DESC
LIMIT 10
