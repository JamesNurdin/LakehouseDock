SELECT
    pl.linktypeid,
    COUNT(*) AS total_postlinks,
    AVG(p_src.score) AS avg_source_score,
    AVG(p_tgt.score) AS avg_target_score,
    COUNT(DISTINCT t.id) AS distinct_tag_count
FROM postlinks AS pl
JOIN posts AS p_src
    ON pl.postid = p_src.id
JOIN posts AS p_tgt
    ON pl.relatedpostid = p_tgt.id
LEFT JOIN tags AS t
    ON t.excerptpostid = p_src.id
GROUP BY pl.linktypeid
ORDER BY total_postlinks DESC
