WITH mc AS (
    SELECT
        mc.movie_id,
        mc.company_id,
        ct.kind,
        mc.note
    FROM movie_companies AS mc
    JOIN company_type AS ct
        ON mc.company_type_id = ct.id
),
note_counts AS (
    SELECT
        kind,
        note,
        COUNT(*) AS note_cnt,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY COUNT(*) DESC) AS rn
    FROM mc
    GROUP BY kind, note
)
SELECT
    kind,
    note,
    note_cnt
FROM note_counts
WHERE rn = 1
ORDER BY kind
