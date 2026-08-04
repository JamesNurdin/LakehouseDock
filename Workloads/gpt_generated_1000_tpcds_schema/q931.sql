WITH
  promo_from_ss AS (
    SELECT DISTINCT p.p_promo_id AS p_id
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  ),
  promo_from_cr AS (
    SELECT DISTINCT p.p_promo_id AS p_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
  ),
  diff_promos AS (
    SELECT p_id FROM promo_from_ss
    EXCEPT
    SELECT p_id FROM promo_from_cr
  )
SELECT
  i.i_item_id,
  COALESCE(p_ss.p_promo_id, p_ws.p_promo_id) AS promo_id,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_sales_profit,
  SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales_profit,
  SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
  SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
  pl.promo_cnt,
  ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(ss.ss_net_profit, 0)) DESC) AS rn
FROM
  item i
  FULL OUTER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  FULL OUTER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  FULL OUTER JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  RIGHT OUTER JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
  LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
  LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
  LEFT JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  LEFT JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  LEFT JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT p2.p_promo_id) AS promo_cnt
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
  ) pl ON TRUE
WHERE
  i.i_current_price > 20
  AND (COALESCE(p_ss.p_promo_id, p_ws.p_promo_id) IN (SELECT p_id FROM diff_promos))
GROUP BY
  i.i_item_id,
  COALESCE(p_ss.p_promo_id, p_ws.p_promo_id),
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  pl.promo_cnt
HAVING
  SUM(COALESCE(ss.ss_net_profit, 0)) > 1000
ORDER BY
  total_store_sales_profit DESC
LIMIT 100
