WITH
  date_filtered AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2002
  ),
  items_sold AS (
    SELECT DISTINCT i.i_item_id
    FROM web_sales ws
    JOIN date_filtered df ON ws.ws_sold_date_sk = df.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
  ),
  items_returned AS (
    SELECT DISTINCT i.i_item_id
    FROM catalog_returns cr
    JOIN date_filtered df ON cr.cr_returned_date_sk = df.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
  ),
  diff_items AS (
    SELECT i_item_id FROM items_sold
    EXCEPT
    SELECT i_item_id FROM items_returned
  ),
  fact_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_brand,
      c.c_customer_id,
      ca.ca_state,
      sm.sm_carrier,
      w.w_state,
      we.web_mkt_id,
      p.p_discount_active,
      ws.ws_net_paid,
      ws.ws_quantity
    FROM web_sales ws
    JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE i.i_brand = 'Brand#12'
      AND sm.sm_carrier = 'UPS'
      AND w.w_state = 'CA'
      AND we.web_mkt_id IN (1, 2)
      AND p.p_discount_active = 'Y'
  )
SELECT
  fb.c_customer_id,
  SUM(fb.ws_net_paid) AS total_net_paid,
  ROW_NUMBER() OVER (ORDER BY SUM(fb.ws_net_paid) DESC) AS customer_rank,
  CASE
    WHEN SUM(fb.ws_net_paid) > (
      SELECT AVG(ws2.ws_net_paid)
      FROM web_sales ws2
      WHERE ws2.ws_sold_date_sk = (
        SELECT MAX(d2.d_date_sk)
        FROM date_dim d2
        WHERE d2.d_year = 2002
      )
    ) THEN 'ABOVE_AVG'
    ELSE 'BELOW_AVG'
  END AS performance_flag,
  di.i_item_id AS diff_item_id
FROM fact_base fb
CROSS JOIN LATERAL (SELECT i_item_id FROM diff_items LIMIT 1) di
GROUP BY fb.c_customer_id, di.i_item_id
ORDER BY total_net_paid DESC
LIMIT 100
