WITH
  sales_data AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_ship_date_sk,
      cs.cs_catalog_page_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cp.cp_catalog_number,
      d_sold.d_year,
      s.s_store_sk,
      s.s_state,
      inv.inv_quantity_on_hand,
      inv.inv_warehouse_sk,
      ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS qty_price_arr
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE cs.cs_ext_list_price > 2000
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND d_sold.d_year = 1999
      AND inv.inv_quantity_on_hand > 500
      AND s.s_state = 'CA'
      AND cp.cp_catalog_number IN (5, 12, 15)
  ),
  returns_data AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_return_amt,
      wr.wr_net_loss,
      d_ret.d_year,
      s.s_store_sk,
      s.s_state,
      inv.inv_quantity_on_hand
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d_ret.d_date_sk
    WHERE wr.wr_return_amt > 1000
      AND d_ret.d_year = 1999
      AND s.s_state = 'CA'
      AND inv.inv_quantity_on_hand > 300
  ),
  intersected_stores AS (
    SELECT s_store_sk FROM sales_data
    INTERSECT
    SELECT s_store_sk FROM returns_data
  )
SELECT
  store_sk,
  year,
  SUM(sales_amount) AS total_sales,
  AVG(profit) AS avg_profit,
  COUNT(*) AS txn_cnt,
  MIN(sales_amount) AS min_sales,
  MAX(sales_amount) AS max_sales
FROM (
  SELECT
    sd.s_store_sk AS store_sk,
    sd.d_year AS year,
    sd.cs_ext_sales_price AS sales_amount,
    sd.cs_net_profit AS profit
  FROM sales_data sd
  CROSS JOIN UNNEST(sd.qty_price_arr) WITH ORDINALITY AS u(val, pos)
  WHERE pos = 1 -- keep the quantity element (just to demonstrate UNNEST)

  UNION DISTINCT

  SELECT
    rd.s_store_sk AS store_sk,
    rd.d_year AS year,
    -rd.wr_return_amt AS sales_amount,
    rd.wr_net_loss AS profit
  FROM returns_data rd
) combined
WHERE combined.store_sk IN (SELECT s_store_sk FROM intersected_stores)
GROUP BY GROUPING SETS ((store_sk, year), (store_sk), (year))
HAVING SUM(sales_amount) > 0
ORDER BY total_sales DESC
LIMIT 100
