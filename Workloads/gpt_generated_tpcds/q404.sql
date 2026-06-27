WITH catalog_sales_q1 AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity,
        cs.cs_ship_mode_sk,
        d.d_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date <= DATE '2001-03-31'
),
web_sales_q1 AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_ship_mode_sk,
        d.d_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date <= DATE '2001-03-31'
),
combined_sales AS (
    SELECT cs_item_sk AS item_sk,
           cs_net_paid_inc_ship_tax AS net_amount,
           cs_quantity AS qty,
           cs_ship_mode_sk AS ship_mode_sk
    FROM catalog_sales_q1
    UNION ALL
    SELECT ws_item_sk AS item_sk,
           ws_net_paid_inc_ship_tax AS net_amount,
           ws_quantity AS qty,
           ws_ship_mode_sk AS ship_mode_sk
    FROM web_sales_q1
)
SELECT
    i.i_category AS category,
    sm.sm_type AS ship_mode_type,
    SUM(cs.net_amount) AS total_net_amount,
    SUM(cs.qty) AS total_quantity,
    COUNT(*) AS transaction_count
FROM combined_sales cs
JOIN item i ON cs.item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY i.i_category, sm.sm_type
ORDER BY total_net_amount DESC
LIMIT 10
