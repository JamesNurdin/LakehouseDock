WITH
   td_sales AS (
      SELECT *
      FROM time_dim
   ),
   td_return AS (
      SELECT *
      FROM time_dim
   )
SELECT
   p1.p_promo_name                AS catalog_promo,
   p2.p_promo_name                AS web_promo,
   td_sales.t_shift               AS sales_shift,
   r1.r_reason_desc               AS catalog_return_reason,
   r2.r_reason_desc               AS store_return_reason,
   SUM(cr.cr_net_loss)            AS total_catalog_return_net_loss,
   SUM(sr.sr_net_loss)            AS total_store_return_net_loss,
   SUM(cs.cs_net_profit)          AS total_catalog_sales_profit,
   SUM(wd.ws_net_profit)          AS total_web_sales_profit,
   COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
INNER JOIN td_sales
        ON cs.cs_sold_time_sk = td_sales.t_time_sk
INNER JOIN promotion p1
        ON cs.cs_promo_sk = p1.p_promo_sk
LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = td_sales.t_time_sk
LEFT JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
INNER JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
INNER JOIN reason r1
        ON cr.cr_reason_sk = r1.r_reason_sk
INNER JOIN td_return
        ON cr.cr_returned_time_sk = td_return.t_time_sk
INNER JOIN web_sales wd
        ON wd.ws_sold_time_sk = td_sales.t_time_sk
INNER JOIN promotion p2
        ON wd.ws_promo_sk = p2.p_promo_sk
GROUP BY
   p1.p_promo_name,
   p2.p_promo_name,
   td_sales.t_shift,
   r1.r_reason_desc,
   r2.r_reason_desc
ORDER BY total_catalog_sales_profit DESC
LIMIT 100
