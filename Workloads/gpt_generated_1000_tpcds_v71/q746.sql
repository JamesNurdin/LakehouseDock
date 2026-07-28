WITH
  store_agg AS (
    SELECT
      i.i_category,
      CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
      SUM(ss.ss_net_profit) AS total_profit,
      SUM(ss.ss_quantity) AS total_qty,
      'store' AS sales_channel
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_category,
      CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
  ),
  web_agg AS (
    SELECT
      i.i_category,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
      SUM(ws.ws_net_profit) AS total_profit,
      SUM(ws.ws_quantity) AS total_qty,
      'web' AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE wp.wp_type = 'Home'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_category,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
  )
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY i_category, profit_status, total_profit DESC
LIMIT 100
