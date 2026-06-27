WITH mc_ct AS (
    SELECT
        mc.movie_id,
        mc.company_id,
        ct.kind,
        mc.note
    FROM movie_companies mc
    JOIN company_type ct
      ON mc.company_type_id = ct.id
)
SELECT
    kind,
    COUNT(*) AS total_associations,
    COUNT(DISTINCT movie_id) AS distinct_movie_count,
    COUNT(DISTINCT company_id) AS distinct_company_count,
    AVG(length(note)) AS avg_note_length,
    MAX(length(note)) AS max_note_length,
    MIN(length(note)) AS min_note_length
FROM mc_ct
GROUP BY kind
HAVING COUNT(*) > 10
ORDER BY total_associations DESC
