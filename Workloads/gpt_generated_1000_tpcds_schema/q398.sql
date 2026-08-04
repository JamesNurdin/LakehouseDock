WITH
  catalog_data AS (
    SELECT
      d.d_year,
      c.c_customer_id,
      ca.ca_state,
      p.p_promo_name AS promo_name,
      sm.sm_type AS ship_type,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(DISTINCT cs.cs_order_number) AS orders,
      AVG(cs.cs_ext_discount_amt) AS avg_discount,
      SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    WHERE ca.ca_state = 'CA'
      AND hd.hd_income_band_sk = 5
      AND p.p_promo_name = 'Holiday Sale'
      AND sm.sm_type = 'AIR'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, c.c_customer_id, ca.ca_state, p.p_promo_name, sm.sm_type
    HAVING SUM(cs.cs_ext_sales_price) > 10000
  ),
  web_data AS (
    SELECT
      d.d_year,
      c.c_customer_id,
      ca.ca_state,
      p.p_promo_name AS promo_name,
      sm.sm_type AS ship_type,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS orders,
      AVG(ws.ws_ext_discount_amt) AS avg_discount,
      SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE ca.ca_state = 'CA'
      AND hd.hd_income_band_sk = 5
      AND p.p_promo_name = 'Holiday Sale'
      AND sm.sm_type = 'AIR'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, c.c_customer_id, ca.ca_state, p.p_promo_name, sm.sm_type
    HAVING SUM(ws.ws_ext_sales_price) > 15000
  ),
  store_data AS (
    SELECT
      d.d_year,
      c.c_customer_id,
      ca.ca_state,
      SUM(sr.sr_return_amt) AS total_return_amount,
      COUNT(DISTINCT sr.sr_ticket_number) AS tickets,
      SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_state = 'CA'
      AND hd.hd_income_band_sk = 5
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, c.c_customer_id, ca.ca_state
  ),
  combined_sales AS (
    SELECT * FROM catalog_data
    UNION
    SELECT * FROM web_data
  )
SELECT
  COALESCE(cs.d_year, st.d_year) AS year,
  COALESCE(cs.c_customer_id, st.c_customer_id) AS customer_id,
  COALESCE(cs.ca_state, st.ca_state) AS state,
  COALESCE(cs.total_sales, 0) AS total_sales,
  COALESCE(st.total_return_amount, 0) AS total_return_amount,
  (COALESCE(cs.total_return_loss, 0) + COALESCE(st.net_loss, 0)) AS total_loss,
  cs.promo_name,
  cs.ship_type
FROM combined_sales cs
FULL OUTER JOIN store_data st
  ON cs.d_year = st.d_year
 AND cs.c_customer_id = st.c_customer_id
 AND cs.ca_state = st.ca_state
WHERE cs.total_sales > (
        SELECT AVG(cs_inner.cs_ext_sales_price)
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_sold_date_sk = 2450915
      )
  AND EXISTS (
        SELECT 1
        FROM promotion p_chk
        WHERE p_chk.p_promo_name = cs.promo_name
          AND p_chk.p_discount_active = 'Y'
      )
ORDER BY total_loss DESC
LIMIT 100
