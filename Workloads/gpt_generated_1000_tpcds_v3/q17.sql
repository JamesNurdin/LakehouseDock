WITH high_profit_states AS (
    SELECT DISTINCT wsit.web_state
    FROM web_sales ws
    INNER JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ws.ws_net_profit > 500
),
store_agg AS (
    SELECT s.s_state AS state,
           d.d_year AS year,
           d.d_moy AS month,
           SUM(sr.sr_net_loss) AS total_net_loss,
           'Store' AS source
    FROM store_returns sr
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND s.s_state IN (SELECT web_state FROM high_profit_states)
    GROUP BY s.s_state, d.d_year, d.d_moy
),
catalog_agg AS (
    SELECT cc.cc_state AS state,
           d.d_year AS year,
           d.d_moy AS month,
           SUM(cr.cr_net_loss) AS total_net_loss,
           'Catalog' AS source
    FROM catalog_returns cr
    INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cc.cc_state IN (SELECT web_state FROM high_profit_states)
    GROUP BY cc.cc_state, d.d_year, d.d_moy
)
SELECT state, year, month, total_net_loss, source
FROM store_agg
UNION ALL
SELECT state, year, month, total_net_loss, source
FROM catalog_agg
ORDER BY total_net_loss DESC
LIMIT 100
