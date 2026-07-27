WITH filtered_inventory AS (
       SELECT inv_item_sk,
              inv_warehouse_sk,
              inv_quantity_on_hand
       FROM inventory
       WHERE inv_quantity_on_hand > 500
   )
SELECT
       s.s_store_id,
       i.i_item_id,
       p.p_promo_name,
       w.w_warehouse_name,
       SUM(ss.ss_ext_sales_price)                     AS total_sales,
       SUM(sr.sr_return_amt)                          AS total_returns,
       SUM(ss.ss_net_profit)                          AS total_profit,
       COUNT(DISTINCT ss.ss_ticket_number)            AS distinct_sales,
       CASE WHEN SUM(ss.ss_net_profit) > 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
       (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promo_count
FROM filtered_inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                     AND ss.ss_promo_sk = p.p_promo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE s.s_country = 'United States'
  AND s.s_rec_start_date >= DATE '2000-01-01'
  AND p.p_channel_email = 'N'
  AND w.w_state = 'CA'
GROUP BY s.s_store_id, i.i_item_id, p.p_promo_name, w.w_warehouse_name
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
