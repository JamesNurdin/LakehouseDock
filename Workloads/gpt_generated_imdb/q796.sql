WITH person_info_enriched AS (
    SELECT
        pi.person_id,
        it.info AS info_type,
        pi.info AS person_info,
        pi.note
    FROM person_info pi
    JOIN info_type it
        ON pi.info_type_id = it.id
    WHERE pi.note IS NOT NULL
),
aggregated AS (
    SELECT
        info_type,
        COUNT(DISTINCT person_id) AS distinct_person_count,
        COUNT(*) AS total_records,
        MIN(person_info) AS sample_person_info,
        MAX(note) AS max_note
    FROM person_info_enriched
    GROUP BY info_type
)
SELECT
    info_type,
    distinct_person_count,
    total_records,
    sample_person_info,
    max_note,
    RANK() OVER (ORDER BY distinct_person_count DESC) AS rank_by_persons
FROM aggregated
ORDER BY distinct_person_count DESC
LIMIT 5
