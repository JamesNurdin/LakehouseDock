WITH
  store_sales_base AS (
    SELECT
      s.s_store_id,
      i.i_category,
      ss.ss_net_paid,
      ss.ss_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_sales_price > 20
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
  ),
  store_sales_agg AS (
    SELECT
      s_store_id,
      i_category,
      SUM(ss_net_paid)   AS total_paid,
      SUM(ss_net_profit) AS total_profit
    FROM store_sales_base
    GROUP BY ROLLUP (s_store_id, i_category)
  ),

  store_returns_base AS (
    SELECT
      s.s_store_id,
      r.r_reason_desc,
      sr.sr_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 10
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
  ),
  store_returns_agg AS (
    SELECT
      s_store_id,
      r_reason_desc,
      SUM(sr_net_loss) AS total_loss
    FROM store_returns_base
    GROUP BY CUBE (s_store_id, r_reason_desc)
  ),

  web_sales_base AS (
    SELECT
      ws.ws_web_site_sk,
      i.i_category,
      ws.ws_net_paid,
      ws.ws_net_profit,
      ws.ws_quantity,
      ws.ws_sales_price,
      ws.ws_ship_mode_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_quantity > 2
      AND ws.ws_sales_price > 30
      AND i.i_brand = 'BrandX'
      AND w.web_state = 'NY'
  ),
  web_sales_agg AS (
    SELECT
      ws_web_site_sk,
      i_category,
      SUM(ws_net_paid)   AS total_paid,
      SUM(ws_net_profit) AS total_profit
    FROM web_sales_base
    GROUP BY ROLLUP (ws_web_site_sk, i_category)
  ),

  web_returns_base AS (
    SELECT
      w.web_site_sk,
      r.r_reason_desc,
      wr.wr_net_loss
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_site w ON wp.wp_web_page_id = w.web_site_id  -- using a varchar key that exists in both tables
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 5
      AND i.i_category = 'Electronics'
  ),
  web_returns_agg AS (
    SELECT
      web_site_sk,
      r_reason_desc,
      SUM(wr_net_loss) AS total_loss
    FROM web_returns_base
    GROUP BY CUBE (web_site_sk, r_reason_desc)
  ),

  catalog_returns_base AS (
    SELECT
      cr.cr_returned_date_sk,
      i.i_category,
      cr.cr_net_loss,
      sm.sm_ship_mode_id,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 15
      AND sm.sm_code = 'AIR'
      AND i.i_category = 'Electronics'
  ),
  catalog_returns_agg AS (
    SELECT
      sm_ship_mode_id,
      i_category,
      SUM(cr_net_loss) AS total_loss
    FROM catalog_returns_base
    GROUP BY ROLLUP (sm_ship_mode_id, i_category)
  ),

  final_union AS (
    SELECT 'Store Sales'       AS source, s_store_id          AS id, i_category AS category, total_paid, total_profit, NULL        AS total_loss FROM store_sales_agg
    UNION ALL
    SELECT 'Store Returns'    AS source, s_store_id          AS id, r_reason_desc AS category, NULL, NULL, total_loss FROM store_returns_agg
    UNION ALL
    SELECT 'Web Sales'        AS source, CAST(ws_web_site_sk AS VARCHAR) AS id, i_category AS category, total_paid, total_profit, NULL FROM web_sales_agg
    UNION ALL
    SELECT 'Web Returns'      AS source, CAST(web_site_sk AS VARCHAR) AS id, r_reason_desc AS category, NULL, NULL, total_loss FROM web_returns_agg
    UNION ALL
    SELECT 'Catalog Returns'  AS source, sm_ship_mode_id     AS id, i_category AS category, NULL, NULL, total_loss FROM catalog_returns_agg
  )
SELECT
  source,
  id,
  category,
  SUM(COALESCE(total_paid, 0))   AS sum_paid,
  SUM(COALESCE(total_profit, 0)) AS sum_profit,
  SUM(COALESCE(total_loss, 0))   AS sum_loss
FROM final_union
GROUP BY GROUPING SETS (
  (source, id, category),
  (source, id),
  (source)
)
HAVING SUM(COALESCE(total_paid, 0)) > 1000
ORDER BY sum_paid DESC
LIMIT 100
