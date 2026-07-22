WITH promo_dim AS (
   SELECT DISTINCT
      p.p_promo_sk,
      p.p_promo_name,
      p.p_discount_active
   FROM promotion p
   JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk OR p.p_end_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001
),
base_agg AS (
   SELECT
      c.c_customer_id,
      d.d_date,
      p.p_promo_name,
      sm.sm_carrier,
      wp.wp_url,
      wsite.web_name,
      SUM(ws.ws_net_paid) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
      SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
      SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_inventory_on_hand
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promo_dim p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
   LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                               AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
                               AND cr.cr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_customer_sk = c.c_customer_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE
      d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND wp.wp_type = 'Content'
      AND p.p_discount_active = 'Y'
      AND sm.sm_carrier = 'UPS'
      AND ca.ca_state = 'CA'
      AND ws.ws_quantity > 1
      AND wsite.web_country = 'United States'
   GROUP BY
      c.c_customer_id,
      d.d_date,
      p.p_promo_name,
      sm.sm_carrier,
      wp.wp_url,
      wsite.web_name
   HAVING
      SUM(ws.ws_net_paid) > 1000
      AND SUM(i.inv_quantity_on_hand) IS NOT NULL
)
SELECT
   agg.c_customer_id,
   agg.d_date,
   agg.p_promo_name,
   agg.sm_carrier,
   agg.wp_url,
   agg.web_name,
   agg.total_sales,
   agg.total_profit,
   agg.total_catalog_return_amount,
   agg.total_store_return_amount,
   agg.total_inventory_on_hand,
   ROW_NUMBER() OVER (PARTITION BY agg.c_customer_id ORDER BY agg.total_sales DESC) AS sales_rank
FROM base_agg agg
ORDER BY agg.total_profit DESC, sales_rank ASC
LIMIT 100
