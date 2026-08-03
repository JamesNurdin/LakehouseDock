WITH
  joined_data AS (
    SELECT
      p.p_promo_name,
      d_year.d_year,
      cc.cc_name,
      cs.cs_net_paid,
      ws.ws_net_paid,
      cs.cs_order_number,
      ws.ws_order_number,
      cs.cs_quantity,
      ws.ws_net_profit,
      ib.ib_upper_bound,
      wp.wp_image_count,
      cc.cc_employees
    FROM catalog_sales cs
    JOIN date_dim d_year
      ON cs.cs_sold_date_sk = d_year.d_date_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_year.d_year = 2000
      AND ib.ib_upper_bound >= 100000
      AND p.p_discount_active = 'Y'
      AND wp.wp_image_count >= 5
      AND CAST(cc.cc_employees AS BIGINT) > 1000000
  ),
  aggregated AS (
    SELECT
      p_promo_name,
      d_year,
      cc_name,
      SUM(cs_net_paid) AS total_catalog_sales,
      SUM(ws_net_paid) AS total_web_sales,
      COUNT(DISTINCT cs_order_number) AS catalog_orders,
      COUNT(DISTINCT ws_order_number) AS web_orders,
      AVG(cs_quantity) AS avg_catalog_qty,
      MAX(ws_net_profit) AS max_web_profit
    FROM joined_data
    GROUP BY p_promo_name, d_year, cc_name
  )
SELECT
  p_promo_name,
  d_year,
  cc_name,
  total_catalog_sales,
  total_web_sales,
  catalog_orders,
  web_orders,
  avg_catalog_qty,
  max_web_profit
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY p_promo_name ORDER BY (total_catalog_sales + total_web_sales) DESC) AS rn
  FROM aggregated
) t
WHERE rn <= 5
LIMIT 100
