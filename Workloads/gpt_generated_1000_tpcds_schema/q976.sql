WITH
  sample_inv AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
    WHERE inv_quantity_on_hand > 0
  ),
  intersect_stores AS (
    SELECT s_store_id FROM store WHERE s_state = 'CA'
    INTERSECT
    SELECT s_store_id FROM store_sales ss JOIN store s2 ON ss.ss_store_sk = s2.s_store_sk WHERE ss.ss_net_paid > 1000
  ),
  base AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS rn_store_sales
    FROM call_center cc
    FULL OUTER JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN sample_inv inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2000
      AND i.i_current_price > 50
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
  ),
  union_part AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS rn_store_sales
    FROM store s
    LEFT JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'TX'
  )
SELECT *
FROM base
WHERE s_store_id IN (SELECT s_store_id FROM intersect_stores)
UNION
SELECT *
FROM union_part
LIMIT 100
