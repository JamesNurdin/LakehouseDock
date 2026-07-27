WITH base AS (
   SELECT
       w.w_warehouse_id,
       w.w_county,
       p.p_promo_id,
       cr.cr_return_amount,
       ws.ws_net_profit
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_county = 'Daviess County'
     AND p.p_discount_active = 'N'
     AND cr.cr_return_quantity > 5
     AND i.i_current_price BETWEEN 10 AND 200
),
agg AS (
   SELECT
       w_warehouse_id,
       w_county,
       p_promo_id,
       SUM(cr_return_amount) AS sum_return_amount,
       SUM(ws_net_profit) AS sum_net_profit,
       COUNT(*) AS txn_cnt
   FROM base
   GROUP BY w_warehouse_id, w_county, p_promo_id
)
SELECT
   w_warehouse_id,
   w_county,
   AVG(sum_net_profit) AS avg_profit_per_promo,
   SUM(sum_return_amount) AS total_return_amount,
   COUNT(*) AS promo_cnt
FROM agg
GROUP BY w_warehouse_id, w_county
HAVING AVG(sum_net_profit) > 500
ORDER BY avg_profit_per_promo DESC
LIMIT 100
