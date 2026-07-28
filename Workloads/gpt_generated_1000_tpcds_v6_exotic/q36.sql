/* goal: Compare morning (8‑12) sales totals per state for catalog and web channels in California, then list the combined results ordered by sales amount */
WITH catalog_agg AS (
    SELECT
        wa.w_state AS state,
        SUM(cs.cs_net_paid) AS total_sales,
        'catalog' AS sales_channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse wa ON cs.cs_warehouse_sk = wa.w_warehouse_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND wa.w_state = 'CA'
    GROUP BY wa.w_state
),
web_agg AS (
    SELECT
        wa.w_state AS state,
        SUM(ws.ws_net_paid) AS total_sales,
        'web' AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse wa ON ws.ws_warehouse_sk = wa.w_warehouse_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND wa.w_state = 'CA'
    GROUP BY wa.w_state
)
SELECT state,
       total_sales,
       sales_channel
FROM catalog_agg
UNION ALL
SELECT state,
       total_sales,
       sales_channel
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
