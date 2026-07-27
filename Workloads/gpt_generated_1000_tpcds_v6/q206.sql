SELECT
    'Store' AS entity_type,
    s.s_state AS location,
    SUM(sr.sr_net_loss) AS metric,
    d.d_year AS year
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d.d_year = 2001
GROUP BY s.s_state, d.d_year

UNION ALL

SELECT
    'WebSite' AS entity_type,
    w.web_state AS location,
    SUM(w.web_tax_percentage) AS metric,
    d.d_year AS year
FROM web_site w
JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY w.web_state, d.d_year

LIMIT 100
