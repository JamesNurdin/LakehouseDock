WITH filtered_sales AS (
   SELECT
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_promo_sk,
       ws.ws_ship_mode_sk,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       ws.ws_sold_time_sk,
       ws.ws_bill_cdemo_sk
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
)
SELECT
   p.p_promo_id,
   p.p_promo_name,
   sm.sm_type,
   cd.cd_gender,
   SUM(fs.ws_ext_sales_price) AS total_sales,
   SUM(fs.ws_net_profit) AS total_profit,
   COALESCE(SUM(r.wr_return_amt), 0) AS total_returns,
   SUM(fs.ws_net_profit) - COALESCE(SUM(r.wr_return_amt), 0) AS net_profit_after_returns
FROM filtered_sales fs
LEFT JOIN web_returns r
   ON fs.ws_order_number = r.wr_order_number
   AND fs.ws_item_sk = r.wr_item_sk
JOIN promotion p ON fs.ws_promo_sk = p.p_promo_sk
   AND p.p_discount_active = 'Y'
JOIN ship_mode sm ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON fs.ws_bill_cdemo_sk = cd.cd_demo_sk
GROUP BY p.p_promo_id, p.p_promo_name, sm.sm_type, cd.cd_gender
ORDER BY net_profit_after_returns DESC
LIMIT 20
