WITH
  base AS (
    SELECT
      d.d_year,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      p.p_promo_id,
      sm.sm_type,
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      ss.ss_ticket_number,
      ss.ss_ext_sales_price AS ss_sales,
      sr.sr_return_quantity,
      ws.ws_order_number,
      ws.ws_net_profit,
      wr.wr_return_quantity,
      wp.wp_type,
      wsite.web_name,
      reason.r_reason_desc
    FROM date_dim d
    JOIN customer c
      ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
         AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
         AND sr.sr_item_sk = ss.ss_item_sk
         AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = d.d_date_sk
         AND cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
         AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
         AND wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason
      ON sr.sr_reason_sk = reason.r_reason_sk
    WHERE d.d_year = 2001
      AND ca.ca_country = 'United States'
      AND ib.ib_upper_bound > 50000
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count > 1
  ),
  aggregated AS (
    SELECT
      d_year,
      p_promo_id,
      c_customer_sk,
      COUNT(DISTINCT cs_order_number) AS catalog_orders,
      SUM(cs_ext_sales_price) AS catalog_sales_total,
      SUM(ss_sales) AS store_sales_total,
      SUM(ws_net_profit) AS web_profit_total,
      AVG(ws_net_profit) AS avg_web_profit
    FROM base
    GROUP BY d_year, p_promo_id, c_customer_sk
  ),
  union_set AS (
    SELECT cs.cs_order_number AS order_id
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    UNION
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
  ),
  intersect_set AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
  ),
  except_set AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    EXCEPT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
  )
SELECT
  a.d_year,
  a.p_promo_id,
  a.c_customer_sk,
  a.catalog_orders,
  a.catalog_sales_total,
  a.store_sales_total,
  a.web_profit_total,
  a.avg_web_profit,
  (SELECT COUNT(*) FROM union_set) AS union_order_cnt,
  (SELECT COUNT(*) FROM intersect_set) AS intersect_order_cnt,
  (SELECT COUNT(*) FROM except_set) AS except_order_cnt
FROM aggregated a
WHERE NOT EXISTS (
  SELECT 1
  FROM web_returns wr
  WHERE wr.wr_refunded_customer_sk = a.c_customer_sk
)
ORDER BY a.catalog_sales_total DESC
LIMIT 100
