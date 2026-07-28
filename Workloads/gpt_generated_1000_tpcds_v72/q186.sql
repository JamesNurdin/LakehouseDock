WITH
  store_data AS (
    SELECT
      ss.ss_sold_date_sk      AS sold_date_sk,
      i.i_category            AS category,
      i.i_brand               AS brand,
      ss.ss_quantity          AS total_quantity,
      ss.ss_net_paid          AS avg_net_paid,
      ss.ss_net_profit        AS total_net_profit,
      s.s_store_name,
      d.cd_gender,
      hd.hd_buy_potential,
      p.p_promo_name
    FROM store_sales ss
    JOIN item i               ON ss.ss_item_sk = i.i_item_sk
    JOIN store s              ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics d ON ss.ss_cdemo_sk = d.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
  ),
  catalog_data AS (
    SELECT
      cs.cs_sold_date_sk      AS sold_date_sk,
      i.i_category            AS category,
      i.i_brand               AS brand,
      cs.cs_quantity          AS total_quantity,
      cs.cs_net_paid          AS avg_net_paid,
      cs.cs_net_profit        AS total_net_profit,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      d.cd_gender,
      hd.hd_buy_potential,
      p.p_promo_name
    FROM catalog_sales cs
    JOIN item i               ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm         ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics d ON cs.cs_bill_cdemo_sk = d.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p          ON cs.cs_promo_sk = p.p_promo_sk
  ),
  web_data AS (
    SELECT
      ws.ws_sold_date_sk      AS sold_date_sk,
      i.i_category            AS category,
      i.i_brand               AS brand,
      ws.ws_quantity          AS total_quantity,
      ws.ws_net_paid          AS avg_net_paid,
      ws.ws_net_profit        AS total_net_profit,
      wp.wp_type,
      ws_site.web_name,
      sm.sm_type,
      w.w_warehouse_name,
      d.cd_gender,
      hd.hd_buy_potential,
      p.p_promo_name
    FROM web_sales ws
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site     ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics d ON ws.ws_bill_cdemo_sk = d.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
  ),
  store_returns_data AS (
    SELECT
      sr.sr_returned_date_sk  AS returned_date_sk,
      i.i_category            AS category,
      i.i_brand               AS brand,
      sr.sr_return_quantity  AS total_quantity,
      sr.sr_return_amt       AS avg_net_paid,
      -sr.sr_net_loss        AS total_net_profit  -- convert loss to positive contribution
    FROM store_returns sr
    JOIN item i               ON sr.sr_item_sk = i.i_item_sk
    JOIN store s              ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics d ON sr.sr_cdemo_sk = d.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  ),
  catalog_returns_data AS (
    SELECT
      cr.cr_returned_date_sk  AS returned_date_sk,
      i.i_category            AS category,
      i.i_brand               AS brand,
      cr.cr_return_quantity  AS total_quantity,
      cr.cr_return_amount    AS avg_net_paid,
      -cr.cr_net_loss        AS total_net_profit
    FROM catalog_returns cr
    JOIN item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc       ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm         ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  ),
  web_returns_data AS (
    SELECT
      wr.wr_returned_date_sk  AS returned_date_sk,
      i.i_category            AS category,
      i.i_brand               AS brand,
      wr.wr_return_quantity  AS total_quantity,
      wr.wr_return_amt       AS avg_net_paid,
      -wr.wr_net_loss        AS total_net_profit
    FROM web_returns wr
    JOIN item i               ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  )
SELECT
  category,
  brand,
  SUM(total_quantity)   AS total_quantity,
  AVG(avg_net_paid)     AS avg_net_paid,
  SUM(total_net_profit) AS total_net_profit
FROM (
  SELECT category, brand, total_quantity, avg_net_paid, total_net_profit FROM store_data
  UNION ALL
  SELECT category, brand, total_quantity, avg_net_paid, total_net_profit FROM catalog_data
  UNION ALL
  SELECT category, brand, total_quantity, avg_net_paid, total_net_profit FROM web_data
  UNION ALL
  SELECT category, brand, total_quantity, avg_net_paid, total_net_profit FROM store_returns_data
  UNION ALL
  SELECT category, brand, total_quantity, avg_net_paid, total_net_profit FROM catalog_returns_data
  UNION ALL
  SELECT category, brand, total_quantity, avg_net_paid, total_net_profit FROM web_returns_data
) agg
WHERE category IS NOT NULL
  AND brand <> ''
  AND total_quantity > 1
  AND avg_net_paid > 100
  AND total_net_profit > 0
GROUP BY category, brand
ORDER BY total_net_profit DESC
LIMIT 100
