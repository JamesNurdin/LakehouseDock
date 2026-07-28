WITH
  sold_sales AS (
    SELECT
      d_sold.d_year AS year,
      c.c_customer_id,
      c.c_customer_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_sold.d_date_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory i ON i.inv_date_sk = d_sold.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2002
    GROUP BY d_sold.d_year, c.c_customer_id, c.c_customer_sk
  ),
  ship_sales AS (
    SELECT
      d_ship.d_year AS year,
      c.c_customer_id,
      c.c_customer_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_ship.d_date_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory i ON i.inv_date_sk = d_ship.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_ship.d_year BETWEEN 2000 AND 2002
    GROUP BY d_ship.d_year, c.c_customer_id, c.c_customer_sk
  ),
  combined AS (
    SELECT DISTINCT * FROM sold_sales
    UNION ALL
    SELECT DISTINCT * FROM ship_sales
  ),
  final AS (
    SELECT
      year,
      c_customer_id,
      SUM(total_sales) AS sum_sales,
      SUM(order_cnt) AS sum_orders,
      ROW_NUMBER() OVER (PARTITION BY year ORDER BY SUM(total_sales) DESC) AS rn,
      c_customer_sk
    FROM combined
    WHERE NOT EXISTS (
      SELECT 1
      FROM web_sales ws2
      JOIN promotion p2 ON ws2.ws_promo_sk = p2.p_promo_sk
      WHERE ws2.ws_bill_customer_sk = combined.c_customer_sk
        AND p2.p_discount_active = 'Y'
    )
    GROUP BY year, c_customer_id, c_customer_sk
  )
SELECT
  year,
  c_customer_id,
  sum_sales,
  sum_orders,
  rn
FROM final
WHERE rn <= 10
ORDER BY year DESC, sum_sales DESC
LIMIT 100
