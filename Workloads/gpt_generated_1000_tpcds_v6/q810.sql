WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM tpcds.catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_catalog_page_sk
)

SELECT
    cc.cc_name               AS entity_name,
    w.w_warehouse_name       AS location,
    sa.total_profit,
    sa.total_quantity
FROM sales_agg sa
JOIN tpcds.call_center cc
  ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
  ON sa.cs_warehouse_sk = w.w_warehouse_sk
WHERE sa.total_profit > (SELECT AVG(total_profit) FROM sales_agg)
  AND EXISTS (
        SELECT 1
        FROM tpcds.warehouse w2
        WHERE w2.w_city = w.w_city
          AND w2.w_state = w.w_state
      )
UNION ALL
SELECT
    cp.cp_catalog_page_id    AS entity_name,
    cp.cp_description        AS location,
    sa.total_profit,
    sa.total_quantity
FROM sales_agg sa
JOIN tpcds.catalog_page cp
  ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE sa.total_quantity > 1000
  AND cp.cp_type = 'A'
ORDER BY total_profit DESC
LIMIT 100
