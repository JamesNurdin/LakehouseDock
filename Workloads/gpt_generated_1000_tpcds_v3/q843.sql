/*
Goal: Calculate per‑store division and web‑site market metrics that combine total net loss from store returns and total net paid from web sales, together with return and ship address city information and overall average net loss. The query joins all five selected tables, reuses several tables under different aliases to create at least nine join clauses, pre‑aggregates the store‑return data in a CTE, includes a scalar subquery, and limits the result to the first 100 rows.
*/
WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_addr_sk
),
ws_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_addr_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_addr_sk
)
SELECT
    s_main.s_division_name,
    s_alt.s_company_name AS store_company_name,
    ca_ret.ca_city AS return_city,
    ca_ret2.ca_city AS return_city_dup,
    ca_ship.ca_city AS ship_city,
    ca_ship2.ca_city AS ship_city_dup,
    sr_agg.total_net_loss,
    sr_agg.return_cnt,
    ws_agg.total_net_paid,
    ws_agg.sales_cnt,
    site_main.web_market_manager,
    site_alt.web_class,
    (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) AS avg_net_loss_all
FROM sr_agg
JOIN store s_main
    ON sr_agg.sr_store_sk = s_main.s_store_sk
JOIN store s_alt
    ON sr_agg.sr_store_sk = s_alt.s_store_sk
JOIN customer_address ca_ret
    ON sr_agg.sr_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ret2
    ON sr_agg.sr_addr_sk = ca_ret2.ca_address_sk
CROSS JOIN ws_agg
JOIN web_site site_main
    ON ws_agg.ws_web_site_sk = site_main.web_site_sk
JOIN web_site site_alt
    ON ws_agg.ws_web_site_sk = site_alt.web_site_sk
JOIN customer_address ca_ship
    ON ws_agg.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_address ca_ship2
    ON ws_agg.ws_ship_addr_sk = ca_ship2.ca_address_sk
WHERE s_main.s_rec_start_date >= DATE '2000-01-01'
  AND site_main.web_company_id = 5
ORDER BY s_main.s_division_name
LIMIT 100
