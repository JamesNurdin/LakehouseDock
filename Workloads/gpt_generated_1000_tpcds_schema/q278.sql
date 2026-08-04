WITH
  item_base AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_category,
      i.i_units,
      i.i_class
    FROM item i
    WHERE i.i_category = 'fragrances'
      AND i.i_units = 'Dozen'
      AND i.i_class = 'fragrances'
  ),
  catalog_join AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_ext_discount_amt,
      cs.cs_net_profit,
      cs.cs_bill_customer_sk,
      cs.cs_warehouse_sk,
      ARRAY[cs.cs_quantity] AS qty_arr
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk = 2451545
      AND cs.cs_ext_sales_price > 1000
  ),
  store_join AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_customer_sk,
      ARRAY[ss.ss_quantity] AS qty_arr
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk = 2451545
      AND ss.ss_ext_sales_price > 500
  ),
  web_join AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_refunded_customer_sk,
      ARRAY[wr.wr_return_quantity] AS qty_arr
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk = 2451545
      AND wr.wr_return_amt > 100
  ),
  customer_join AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_current_hdemo_sk
    FROM customer c
    WHERE c.c_current_hdemo_sk IN (7135, 1404, 2471)
  ),
  warehouse_join AS (
    SELECT
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_state
    FROM warehouse w
    WHERE w.w_state = 'CA'
  )
SELECT
  i.i_item_id,
  i.i_category,
  COALESCE(w.w_warehouse_name, 'UNKNOWN') AS warehouse_name,
  SUM(COALESCE(cj.cs_ext_sales_price, 0)) AS total_catalog_sales,
  SUM(COALESCE(sj.ss_ext_sales_price, 0)) AS total_store_sales,
  SUM(COALESCE(wj.wr_return_amt, 0)) AS total_return_amount,
  COUNT(DISTINCT COALESCE(cj.cs_bill_customer_sk, sj.ss_customer_sk, wj.wr_refunded_customer_sk)) AS distinct_customers,
  ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(cj.cs_ext_sales_price, 0)) DESC) AS revenue_rank,
  qty
FROM item_base i
LEFT JOIN catalog_join cj ON i.i_item_sk = cj.cs_item_sk
FULL OUTER JOIN warehouse_join w ON cj.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_join sj ON i.i_item_sk = sj.ss_item_sk
LEFT JOIN web_join wj ON i.i_item_sk = wj.wr_item_sk
LEFT JOIN customer_join cu ON cu.c_customer_sk = COALESCE(cj.cs_bill_customer_sk, sj.ss_customer_sk, wj.wr_refunded_customer_sk)
CROSS JOIN UNNEST(
  COALESCE(cj.qty_arr, ARRAY[]) ||
  COALESCE(sj.qty_arr, ARRAY[]) ||
  COALESCE(wj.qty_arr, ARRAY[])
) AS t(qty)
GROUP BY
  i.i_item_id,
  i.i_category,
  COALESCE(w.w_warehouse_name, 'UNKNOWN'),
  qty
ORDER BY
  total_catalog_sales DESC,
  revenue_rank
LIMIT 100
