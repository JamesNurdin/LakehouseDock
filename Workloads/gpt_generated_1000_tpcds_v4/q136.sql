WITH joined AS (
   SELECT
     cs.cs_item_sk,
     cs.cs_net_profit AS cs_profit,
     cs.cs_order_number,
     cs.cs_quantity,
     cs.cs_sold_date_sk,
     p.p_promo_id,
     p.p_promo_name,
     p.p_end_date_sk,
     p.p_channel_press,
     ws.ws_net_profit AS ws_profit,
     ws.ws_order_number,
     ws.ws_sold_date_sk,
     wp.wp_max_ad_count,
     wp.wp_url,
     hd.hd_demo_sk
   FROM catalog_sales cs
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN web_sales ws
     ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_returns wr
     ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE p.p_end_date_sk BETWEEN 2450500 AND 2450800
     AND p.p_channel_press = 'N'
     AND wp.wp_max_ad_count >= 2
     AND ws.ws_sold_date_sk BETWEEN 2452000 AND 2452100
     AND EXISTS (
       SELECT 1 FROM store_returns sr
       WHERE sr.sr_item_sk = cs.cs_item_sk
         AND sr.sr_hdemo_sk = hd.hd_demo_sk
         AND sr.sr_return_ship_cost > 50
     )
)
SELECT
  p_promo_id,
  p_promo_name,
  cs_item_sk,
  SUM(cs_profit + ws_profit) AS total_net_profit,
  COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws_order_number) AS web_order_cnt,
  ROW_NUMBER() OVER (ORDER BY SUM(cs_profit + ws_profit) DESC) AS profit_rank
FROM joined
GROUP BY
  p_promo_id,
  p_promo_name,
  cs_item_sk
ORDER BY profit_rank
LIMIT 100
