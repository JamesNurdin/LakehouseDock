WITH sales_agg AS (
  SELECT
    w.w_city,
    w.w_suite_number,
    cp.cp_catalog_page_id,
    cp.cp_description,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS txn_count,
    SUM(i.inv_quantity_on_hand) AS total_on_hand
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
    AND i.inv_item_sk = cs.cs_item_sk
  WHERE regexp_like(cp.cp_description, '\\d{3}')
    AND w.w_city LIKE 'P%'
    AND regexp_like(w.w_suite_number, 'Suite [A-Z]')
  GROUP BY w.w_city, w.w_suite_number, cp.cp_catalog_page_id, cp.cp_description
  HAVING COUNT(*) > 3
)
SELECT
  w_city,
  w_suite_number,
  cp_catalog_page_id,
  substr(cp_description, 1, 30) || '...' AS short_desc,
  total_ext_sales,
  total_net_profit,
  txn_count,
  total_on_hand,
  profit_category,
  rn,
  prev_sales,
  running_sales
FROM (
  SELECT
    w_city,
    w_suite_number,
    cp_catalog_page_id,
    cp_description,
    total_ext_sales,
    total_net_profit,
    txn_count,
    total_on_hand,
    CASE
      WHEN total_net_profit > 20000 THEN 'High'
      WHEN total_net_profit > 5000 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_ext_sales DESC) AS rn,
    LAG(total_ext_sales) OVER (PARTITION BY w_city ORDER BY total_ext_sales DESC) AS prev_sales,
    SUM(total_ext_sales) OVER (
      PARTITION BY w_city
      ORDER BY total_ext_sales DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales
  FROM sales_agg
  WHERE total_ext_sales > 5000
) sub
WHERE rn <= 5
ORDER BY w_city, total_ext_sales DESC
LIMIT 100
