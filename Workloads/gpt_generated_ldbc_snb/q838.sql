/*
  Analytical query: members per forum broken down by gender, showing the count, total members,
  gender percentage, and the earliest membership creation date for each gender.
*/
WITH forum_gender_stats AS (
    SELECT
        f.forum_id,
        p.gender,
        COUNT(*) AS gender_member_cnt,
        MIN(f.creation_date) AS earliest_membership_date
    FROM forum_has_member_person f
    JOIN person p
        ON f.person_id = p.id
    GROUP BY f.forum_id, p.gender
),
forum_total AS (
    SELECT
        forum_id,
        SUM(gender_member_cnt) AS total_members
    FROM forum_gender_stats
    GROUP BY forum_id
)
SELECT
    g.forum_id,
    g.gender,
    g.gender_member_cnt,
    t.total_members,
    ROUND(100.0 * g.gender_member_cnt / t.total_members, 2) AS gender_pct,
    g.earliest_membership_date
FROM forum_gender_stats g
JOIN forum_total t
    ON g.forum_id = t.forum_id
ORDER BY g.forum_id, g.gender_member_cnt DESC
