/*
  Analytical query: Top 10 forums by number of distinct commenters,
  showing moderator gender, counts of distinct likers, distinct interest tags
  of commenters and likers, and the number of commenters who are students.
*/
SELECT
    f.id AS forum_id,
    f.title,
    p_mod.gender AS moderator_gender,
    COUNT(DISTINCT c.creator_person_id) AS num_commenters,
    COUNT(DISTINCT pl.person_id) AS num_likers,
    COUNT(DISTINCT i.tag_id) AS num_tags_commenters,
    COUNT(DISTINCT i2.tag_id) AS num_tags_likers,
    COUNT(DISTINCT CASE WHEN su.class_year IS NOT NULL THEN p_comment.id END) AS num_student_commenters
FROM forum f
LEFT JOIN person p_mod
    ON f.moderator_person_id = p_mod.id
LEFT JOIN post po
    ON po.container_forum_id = f.id
LEFT JOIN comment c
    ON c.parent_post_id = po.id
LEFT JOIN person p_comment
    ON c.creator_person_id = p_comment.id
LEFT JOIN person_has_interest_tag i
    ON i.person_id = p_comment.id
LEFT JOIN person_study_at_university su
    ON su.person_id = p_comment.id
LEFT JOIN person_likes_post pl
    ON pl.post_id = po.id
LEFT JOIN person p_like
    ON pl.person_id = p_like.id
LEFT JOIN person_has_interest_tag i2
    ON i2.person_id = p_like.id
GROUP BY f.id, f.title, p_mod.gender
ORDER BY num_commenters DESC
LIMIT 10
