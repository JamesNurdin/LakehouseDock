WITH
  date_filt AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1 AND 12
  ),
  orders_diff AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 0
  ),
  orders_intersect AS (
    SELECT ss_ticket_number AS order_number
    FROM store_sales
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
  ),
  avg_catalog_discount AS (
    SELECT avg(cs_ext_discount_amt) AS avg_disc
    FROM catalog_sales
    WHERE cs_quantity > 10
  )
SELECT
  d.d_year,
  i.i_brand,
  hd.hd_buy_potential,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
  AVG(p.p_cost) AS avg_promo_cost,
  MAX(cr.cr_return_quantity) AS max_return_qty,
  (SELECT avg_disc FROM avg_catalog_discount) AS avg_catalog_discount,
  (SELECT COUNT(*) FROM orders_diff) AS diff_order_count,
  (SELECT COUNT(*) FROM orders_intersect) AS intersect_order_count
FROM
  catalog_sales cs
  JOIN date_filt d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                     AND ss.ss_customer_sk = c.c_customer_sk
                     AND ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_bill_customer_sk = c.c_customer_sk
                     AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                      AND wr.wr_item_sk = i.i_item_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN LATERAL (
    SELECT array_agg(DISTINCT cs2.cs_order_number) AS order_array
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
  ) la ON true
  CROSS JOIN UNNEST(la.order_array) AS t(order_number)
WHERE
  i.i_brand = 'Brand#12'
  AND ib.ib_lower_bound >= 50000
  AND p.p_channel_event = 'N'
  AND t.order_number IN (SELECT cs_order_number FROM orders_diff)
GROUP BY
  d.d_year,
  i.i_brand,
  hd.hd_buy_potential
ORDER BY
  total_catalog_sales DESC
LIMIT 100
