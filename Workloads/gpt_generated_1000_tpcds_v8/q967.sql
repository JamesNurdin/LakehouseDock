/* goal: Identify, by year/month and promotion, the total sales, profit and return quantities for customers who have store returns but never had web returns, and rank the periods by profit. */
WITH
  -- customers with at least one store return
  cust_store_ret AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  ),
  -- customers with at least one web return
  cust_web_ret AS (
    SELECT DISTINCT c.c_customer_sk
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  ),
  -- customers that appear only in store returns (store‑only customers)
  cust_only_store AS (
    SELECT c_customer_sk FROM cust_store_ret
    EXCEPT
    SELECT c_customer_sk FROM cust_web_ret
  ),
  -- core fact table enriched with all needed dimensions and a lateral sub‑query for return aggregates
  base AS (
    SELECT
      ss.ss_ticket_number,
      d_sale.d_year,
      d_sale.d_month_seq,
      p.p_promo_name,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ss.ss_net_profit,
      ss.ss_ext_sales_price,
      COALESCE(lr.total_store_return_qty, 0) AS total_store_return_qty,
      COALESCE(lr.total_web_return_qty, 0)   AS total_web_return_qty,
      CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
      c.c_customer_sk
    FROM store_sales ss
      JOIN date_dim d_sale        ON ss.ss_sold_date_sk = d_sale.d_date_sk
      JOIN time_dim t_sale        ON ss.ss_sold_time_sk = t_sale.t_time_sk
      JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
      LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
      LEFT JOIN reason r_store_ret ON sr.sr_reason_sk = r_store_ret.r_reason_sk
      JOIN web_sales ws          ON ss.ss_item_sk = ws.ws_item_sk
      JOIN date_dim d_ship       ON ws.ws_ship_date_sk = d_ship.d_date_sk
      JOIN time_dim t_ship       ON ws.ws_sold_time_sk = t_ship.t_time_sk
      JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN web_site wsit         ON ws.ws_web_site_sk = wsit.web_site_sk
      JOIN ship_mode sm_ws       ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
      LEFT JOIN web_returns wr  ON ws.ws_order_number = wr.wr_order_number
      LEFT JOIN reason r_web_ret ON wr.wr_reason_sk = r_web_ret.r_reason_sk
      LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_refunded_customer_sk
      LEFT JOIN catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      LEFT JOIN ship_mode sm_cr   ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
      LEFT JOIN reason r_cat_ret ON cr.cr_reason_sk = r_cat_ret.r_reason_sk
      LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
      LEFT JOIN date_dim d_cp_end   ON cp.cp_end_date_sk   = d_cp_end.d_date_sk
      LEFT JOIN LATERAL (
        SELECT
          SUM(sr2.sr_return_quantity) AS total_store_return_qty,
          SUM(wr2.wr_return_quantity) AS total_web_return_qty
        FROM store_returns sr2
        LEFT JOIN web_returns wr2 ON sr2.sr_ticket_number = wr2.wr_order_number
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
      ) lr ON TRUE
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM cust_only_store)
  )
SELECT
  base.d_year,
  base.d_month_seq,
  base.p_promo_name,
  base.profit_category,
  SUM(base.ss_ext_sales_price)            AS total_sales,
  SUM(base.ss_net_profit)                 AS total_profit,
  SUM(base.total_store_return_qty)        AS store_returns_qty,
  SUM(base.total_web_return_qty)          AS web_returns_qty,
  ROW_NUMBER() OVER (ORDER BY SUM(base.ss_net_profit) DESC) AS rn,
  SUM(SUM(base.ss_net_profit)) OVER (
    PARTITION BY base.d_year
    ORDER BY base.d_month_seq
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cum_year_profit
FROM base
GROUP BY
  base.d_year,
  base.d_month_seq,
  base.p_promo_name,
  base.profit_category
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
