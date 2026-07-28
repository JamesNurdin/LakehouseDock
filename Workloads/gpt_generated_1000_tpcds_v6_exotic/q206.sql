WITH date_filter AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
)
SELECT sales_channel,
       sales_year,
       sales_state,
       total_sales
FROM (
    SELECT
        'Catalog' AS sales_channel,
        d.d_year AS sales_year,
        w.w_state AS sales_state,
        SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN date_filter d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'GA'
    GROUP BY d.d_year, w.w_state

    UNION ALL

    SELECT
        'Web' AS sales_channel,
        d.d_year AS sales_year,
        w.w_state AS sales_state,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN date_filter d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'GA'
    GROUP BY d.d_year, w.w_state
) AS combined_sales
ORDER BY sales_year, sales_state, sales_channel
LIMIT 100
