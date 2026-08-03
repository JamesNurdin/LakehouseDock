WITH
  base AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_promo_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      p.p_promo_name,
      d.d_year,
      ca.ca_state,
      c.c_first_name,
      c.c_last_name,
      hd.hd_income_band_sk,
      inv.inv_quantity_on_hand,
      ws.ws_order_number,
      ws.ws_quantity AS ws_quantity,
      ws.ws_net_paid AS ws_net_paid,
      wp.wp_type,
      ws.ws_web_site_sk,
      ws.ws_web_page_sk,
      ws.ws_sold_date_sk AS ws_sold_date_sk,
      cc.cc_company,
      cp.cp_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON ss.ss_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
    JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND d.d_date_sk = ws.ws_sold_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND i.i_current_price > 20
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND cc.cc_company IN (1, 2, 3)
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'C'
      AND i.i_brand_id IN (SELECT i_brand_id FROM item WHERE i_current_price > 100)
  ),
  agg AS (
    SELECT
      b.ss_store_sk,
      b.p_promo_name,
      SUM(b.ss_net_paid) AS store_promo_sales,
      COUNT(DISTINCT b.ss_customer_sk) AS cust_cnt,
      CASE WHEN SUM(b.ss_quantity) > 500 THEN 'BIG' ELSE 'SMALL' END AS qty_category
    FROM base b
    GROUP BY ROLLUP (b.ss_store_sk, b.p_promo_name)
  ),
  ranked AS (
    SELECT
      a.ss_store_sk,
      a.p_promo_name,
      a.store_promo_sales,
      a.cust_cnt,
      a.qty_category,
      RANK() OVER (PARTITION BY a.ss_store_sk ORDER BY a.store_promo_sales DESC) AS promo_rank,
      l.store_total_sales
    FROM agg a
    LEFT JOIN LATERAL (
      SELECT SUM(store_promo_sales) AS store_total_sales
      FROM agg a2
      WHERE a2.ss_store_sk = a.ss_store_sk
    ) l ON TRUE
    WHERE a.ss_store_sk IS NOT NULL AND a.p_promo_name IS NOT NULL
  )
SELECT
  ss_store_sk,
  p_promo_name,
  store_promo_sales,
  cust_cnt,
  qty_category,
  store_total_sales,
  promo_rank
FROM ranked
WHERE promo_rank <= 3
ORDER BY ss_store_sk, promo_rank
LIMIT 100
