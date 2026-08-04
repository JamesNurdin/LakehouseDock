/*
  Goal: Produce a per‑warehouse, per‑product profit summary for sales that have a matching return,
        categorising quantity size, applying a CASE expression, lateral discount aggregation,
        and filtering to only those orders that appear in web_sales but not in web_returns.
        The query demonstrates deep joins across all 14 TPC‑DS tables, re‑uses the CUSTOMER
        dimension under two aliases, uses UNION, EXCEPT, a scalar sub‑query, a correlated EXISTS,
        a LATERAL sub‑query and finally pages the result.
*/
WITH
  /* Base fact table joined to all dimensions */
  base_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_warehouse_sk,
      ws.ws_quantity,
      ws.ws_sales_price,
      ws.ws_net_profit,
      i.i_product_name,
      w.w_warehouse_name,
      hd_bill.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      inv.inv_quantity_on_hand,
      wp.wp_url,
      p.p_promo_name,
      t_sold.t_hour,
      -- lateral sub‑query: total discount for the same item‑warehouse pair
      ld.total_discount,
      -- reuse of CUSTOMER and HOUSEHOLD_DEMOGRAPHICS under different aliases
      bill_cust.c_customer_id AS bill_customer_id,
      ship_cust.c_customer_id AS ship_customer_id,
      hd_ship.hd_income_band_sk AS ship_income_band_sk,
      cr.cr_order_number AS cr_order_number,
      cc.cc_name AS call_center_name,
      cp.cp_description AS catalog_page_desc
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer bill_cust ON ws.ws_bill_customer_sk = bill_cust.c_customer_sk
    JOIN customer ship_cust ON ws.ws_ship_customer_sk = ship_cust.c_customer_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN LATERAL (
      SELECT sum(ws2.ws_ext_discount_amt) AS total_discount
      FROM web_sales ws2
      WHERE ws2.ws_item_sk = ws.ws_item_sk
        AND ws2.ws_warehouse_sk = ws.ws_warehouse_sk
    ) ld ON true
    WHERE ws.ws_sales_price > (
            SELECT max(ws3.ws_sales_price) FROM web_sales ws3
          )
  ),

  /* Set of order numbers coming from sales and catalog returns */
  union_orders AS (
    SELECT ws_order_number FROM base_sales
    UNION
    SELECT cr_order_number FROM catalog_returns
  ),

  /* Set of order numbers that have a web return */
  returns_orders AS (
    SELECT wr_order_number FROM web_returns
  ),

  /* Orders that are in sales/returns union but not in web returns */
  orders_to_keep AS (
    SELECT ws_order_number FROM union_orders
    EXCEPT
    SELECT wr_order_number FROM returns_orders
  ),

  /* Filtered rows that have at least one matching return (correlated EXISTS) */
  filtered_sales AS (
    SELECT
      bs.ws_order_number,
      bs.w_warehouse_name,
      bs.i_product_name,
      bs.ws_quantity,
      bs.ws_net_profit,
      CASE WHEN bs.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS quantity_category,
      bs.total_discount,
      bs.ib_upper_bound
    FROM base_sales bs
    JOIN orders_to_keep okt ON bs.ws_order_number = okt.ws_order_number
    WHERE EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_order_number = bs.ws_order_number
          )
  )
SELECT
  fs.w_warehouse_name,
  fs.i_product_name,
  fs.quantity_category,
  sum(fs.ws_net_profit)          AS total_net_profit,
  sum(fs.total_discount)          AS total_discount,
  count(DISTINCT fs.ws_order_number) AS orders_count
FROM filtered_sales fs
GROUP BY
  fs.w_warehouse_name,
  fs.i_product_name,
  fs.quantity_category
ORDER BY total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
