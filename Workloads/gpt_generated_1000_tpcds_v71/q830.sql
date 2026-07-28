/* goal: Analyze total sales across catalog, store, and web channels by product category, year and state, while excluding any items that had a web return in the same year. The query joins all 16 TPC‑DS tables, re‑uses the date_dim table under multiple aliases, and includes an anti‑join via NOT EXISTS. */
WITH
  -- First set of date dimensions for catalog sales (sold and ship dates)
  d_sold AS (
    SELECT * FROM date_dim WHERE d_current_quarter = 'Y'
  ),
  d_ship AS (
    SELECT * FROM date_dim
  ),
  -- Date dimension for store sales
  d_ss_sold AS (
    SELECT * FROM date_dim
  ),
  -- Date dimensions for web sales (sold and ship dates)
  d_ws_sold AS (
    SELECT * FROM date_dim
  ),
  d_ws_ship AS (
    SELECT * FROM date_dim
  ),
  -- Date dimension for web returns
  d_wr_returned AS (
    SELECT * FROM date_dim
  ),
  -- Date dimension used only for the anti‑join filter
  d_no_return AS (
    SELECT * FROM date_dim
  )
SELECT
  i.i_category               AS category,
  d_sold.d_year               AS year,
  s.s_state                   AS state,
  SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
  SUM(ss.ss_ext_sales_price) AS store_sales_amount,
  SUM(ws.ws_ext_sales_price) AS web_sales_amount,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
  JOIN d_sold               ON cs.cs_sold_date_sk   = d_sold.d_date_sk
  JOIN d_ship               ON cs.cs_ship_date_sk   = d_ship.d_date_sk
  JOIN time_dim t_cs_sold   ON cs.cs_sold_time_sk   = t_cs_sold.t_time_sk
  JOIN customer c_bill      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib       ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN item i               ON cs.cs_item_sk       = i.i_item_sk
  JOIN warehouse w          ON cs.cs_warehouse_sk  = w.w_warehouse_sk
  -- Store sales side
  JOIN store_sales ss       ON ss.ss_item_sk   = i.i_item_sk
                              AND ss.ss_customer_sk = c_bill.c_customer_sk
  JOIN d_ss_sold            ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
  JOIN time_dim t_ss_sold   ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
  JOIN store s              ON ss.ss_store_sk  = s.s_store_sk
  -- Web sales side
  JOIN web_sales ws         ON ws.ws_item_sk   = i.i_item_sk
                              AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN d_ws_sold            ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN d_ws_ship            ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  JOIN time_dim t_ws_sold   ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
  JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite       ON ws.ws_web_site_sk = wsite.web_site_sk
  -- Web returns side (joined for completeness, not used in SELECT)
  JOIN web_returns wr       ON wr.wr_order_number = ws.ws_order_number
  JOIN d_wr_returned        ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
  JOIN time_dim t_wr_returned ON wr.wr_returned_time_sk = t_wr_returned.t_time_sk
  -- Inventory side
  JOIN inventory inv        ON inv.inv_item_sk   = i.i_item_sk
                              AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN d_no_return         ON inv.inv_date_sk = d_no_return.d_date_sk
WHERE cs.cs_quantity > 1
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN d_no_return dr2 ON wr2.wr_returned_date_sk = dr2.d_date_sk
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND dr2.d_year = d_sold.d_year
      )
GROUP BY i.i_category,
         d_sold.d_year,
         s.s_state
ORDER BY SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) DESC
LIMIT 100
