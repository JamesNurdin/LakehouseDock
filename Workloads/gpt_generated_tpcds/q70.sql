/*
  Net profit by state, month, and sales channel (store, catalog, web).
  The query joins each sales fact table to the date dimension and
  customer address to obtain the year, month, and state, then aggregates
  net profit and transaction count.
*/
WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ca.ca_state AS state,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        ca.ca_state AS state,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ca.ca_state AS state,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    d.d_year,
    d.d_moy,
    combined.state,
    combined.channel,
    SUM(combined.net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM combined_sales combined
JOIN date_dim d ON combined.date_sk = d.d_date_sk
GROUP BY d.d_year, d.d_moy, combined.state, combined.channel
ORDER BY d.d_year, d.d_moy, combined.state, combined.channel
