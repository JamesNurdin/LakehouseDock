WITH agg_store_year AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_market_id,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_returns,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_returns
  FROM date_dim d
  JOIN store s               ON s.s_closed_date_sk = d.d_date_sk
  JOIN catalog_page cp       ON cp.cp_start_date_sk = d.d_date_sk
  JOIN promotion p           ON p.p_start_date_sk = d.d_date_sk
  JOIN customer c            ON c.c_first_sales_date_sk = d.d_date_sk
  JOIN store_sales ss        ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store_returns sr      ON sr.sr_returned_date_sk = d.d_date_sk
                              AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN web_sales ws          ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_returns wr        ON wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_order_number = ws.ws_order_number
  JOIN item i                ON i.i_item_sk = ss.ss_item_sk
  JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
  JOIN income_band ib        ON ib.ib_income_band_sk = hd.hd_income_band_sk
  JOIN reason r_sr           ON r_sr.r_reason_sk = sr.sr_reason_sk
  JOIN reason r_wr           ON r_wr.r_reason_sk = wr.wr_reason_sk
  JOIN ship_mode sm          ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
  JOIN warehouse w           ON w.w_warehouse_sk = ws.ws_warehouse_sk
  JOIN web_page wp           ON wp.wp_web_page_sk = ws.ws_web_page_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND s.s_market_id IN (1, 3, 5)
    AND i.i_current_price > 20
    AND ib.ib_lower_bound >= 20000
    AND p.p_discount_active = 'Y'
  GROUP BY s.s_store_sk, s.s_store_name, s.s_market_id, d.d_year
)
SELECT
  a.s_market_id,
  AVG(a.total_store_sales + a.total_web_sales) AS avg_total_sales,
  COUNT(*) AS store_count,
  CASE WHEN AVG(a.total_store_sales + a.total_web_sales) > 150000 THEN 'TOP' ELSE 'REGULAR' END AS market_category
FROM agg_store_year a
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr_ex
        WHERE sr_ex.sr_store_sk = a.s_store_sk
      )
GROUP BY a.s_market_id
HAVING AVG(a.total_store_sales + a.total_web_sales) > 50000
ORDER BY avg_total_sales DESC
LIMIT 100
