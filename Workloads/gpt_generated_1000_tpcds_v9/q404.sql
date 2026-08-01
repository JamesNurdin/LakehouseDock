WITH
  distinct_items AS (
    SELECT DISTINCT
      i.i_item_sk,
      i.i_category_id,
      inv.inv_warehouse_sk
    FROM
      item i
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
      i.i_category_id = 10
      AND i.i_wholesale_cost > 20.00
      AND inv.inv_warehouse_sk IN (1, 3, 15)
  ),
  sales_agg AS (
    SELECT
      i.i_category_id AS category_id,
      inv.inv_warehouse_sk AS warehouse_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_quantity,
      AVG(ss.ss_net_profit) AS avg_profit,
      COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
    FROM
      store_sales ss
      JOIN item i ON ss.ss_item_sk = i.i_item_sk
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
      JOIN distinct_items di ON di.i_item_sk = i.i_item_sk
    WHERE
      ss.ss_coupon_amt > 0.00
    GROUP BY
      ROLLUP(i.i_category_id, inv.inv_warehouse_sk)
  )
SELECT
  category_id,
  warehouse_sk,
  total_sales,
  total_quantity,
  avg_profit,
  distinct_items_sold,
  CASE
    WHEN total_sales >= 100000 THEN 'High'
    WHEN total_sales >= 50000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_bucket,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM
  sales_agg
ORDER BY
  sales_rank
LIMIT 100
