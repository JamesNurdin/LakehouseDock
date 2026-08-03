WITH
  -- Store sales with several dimensional joins and filters
  store_sales_enhanced AS (
    SELECT
      i.i_category,
      d.d_year,
      ss.ss_ext_sales_price   AS revenue,
      ss.ss_net_profit        AS profit,
      s.s_state,
      hd.hd_income_band_sk,
      c.c_preferred_cust_flag
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i               ON ss.ss_item_sk = i.i_item_sk
    JOIN store s              ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer c          ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'TX'
      AND hd.hd_income_band_sk = 5
  ),

  -- Web sales enriched with warehouse and site information
  web_sales_enhanced AS (
    SELECT
      i.i_category,
      d.d_year,
      ws.ws_ext_sales_price AS revenue,
      ws.ws_net_profit      AS profit,
      w.w_city,
      ws.ws_quantity > 0   AS qty_positive,
      ws.ws_web_site_sk
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site wsit        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND w.w_city = 'Seattle'
  ),

  -- Store returns with reason description
  store_returns_enhanced AS (
    SELECT
      i.i_category,
      d.d_year,
      -sr.sr_return_amt AS revenue,
      -sr.sr_net_loss   AS profit,
      r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i           ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
  ),

  -- Web returns with reason description
  web_returns_enhanced AS (
    SELECT
      i.i_category,
      d.d_year,
      -wr.wr_return_amt AS revenue,
      -wr.wr_net_loss   AS profit,
      r.r_reason_desc
    FROM web_returns wr
    JOIN date_dim d      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i           ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r         ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
  ),

  -- Catalog returns, linking to catalog page and reason
  catalog_returns_enhanced AS (
    SELECT
      i.i_category,
      d.d_year,
      -cr.cr_return_amount AS revenue,
      -cr.cr_net_loss      AS profit,
      cp.cp_department,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim d          ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
  ),

  -- Inventory snapshot (joined but not directly used in aggregates)
  inventory_snapshot AS (
    SELECT
      i.i_category,
      d.d_year,
      inv.inv_quantity_on_hand,
      w.w_warehouse_name
    FROM inventory inv
    JOIN date_dim d      ON inv.inv_date_sk = d.d_date_sk
    JOIN item i           ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
  )

SELECT
  category,
  year,
  SUM(revenue) AS total_revenue,
  SUM(profit)  AS total_profit,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY SUM(revenue) DESC) AS revenue_rank
FROM (
  SELECT i_category AS category, d_year AS year, revenue, profit FROM store_sales_enhanced
  UNION ALL
  SELECT i_category, d_year, revenue, profit FROM web_sales_enhanced
  UNION ALL
  SELECT i_category, d_year, revenue, profit FROM store_returns_enhanced
  UNION ALL
  SELECT i_category, d_year, revenue, profit FROM web_returns_enhanced
  UNION ALL
  SELECT i_category, d_year, revenue, profit FROM catalog_returns_enhanced
) t
GROUP BY category, year
HAVING SUM(revenue) > 10000
ORDER BY year, revenue_rank
LIMIT 20
