WITH joined_data AS (
   SELECT
     s.s_store_sk,
     s.s_store_name,
     s.s_state,
     p.p_promo_sk,
     p.p_promo_name,
     i.i_item_sk,
     i.i_product_name,
     w.w_warehouse_sk,
     w.w_warehouse_name,
     w.w_country,
     t.t_hour,
     ss.ss_net_profit,
     ss.ss_quantity,
     cr.cr_return_amount,
     wr.wr_return_amt,
     inv.inv_quantity_on_hand,
     wp.wp_web_page_id,
     r.r_reason_desc
   FROM store_sales ss
   JOIN time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN catalog_returns cr
     ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
   LEFT JOIN warehouse w
     ON w.w_warehouse_sk = inv.inv_warehouse_sk
   LEFT JOIN web_page wp
     ON wp.wp_web_page_sk = wr.wr_web_page_sk
   LEFT JOIN reason r
     ON r.r_reason_sk = COALESCE(cr.cr_reason_sk, wr.wr_reason_sk)
   WHERE t.t_hour BETWEEN 8 AND 17
     AND s.s_state = 'CA'
     AND w.w_country = 'United States'
     AND p.p_discount_active = 'Y'
),
agg AS (
   SELECT
     s_store_sk,
     s_store_name,
     p_promo_sk,
     p_promo_name,
     w_warehouse_sk,
     w_warehouse_name,
     SUM(ss_net_profit) AS total_net_profit,
     SUM(ss_quantity) AS total_units_sold,
     SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return,
     SUM(COALESCE(wr_return_amt, 0)) AS total_web_return,
     SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_qty,
     COUNT(DISTINCT i_item_sk) AS distinct_items_sold
   FROM joined_data
   GROUP BY s_store_sk,
            s_store_name,
            p_promo_sk,
            p_promo_name,
            w_warehouse_sk,
            w_warehouse_name
)
SELECT
   a.s_store_name,
   a.p_promo_name,
   a.w_warehouse_name,
   a.total_net_profit,
   a.total_units_sold,
   a.total_catalog_return,
   a.total_web_return,
   a.total_inventory_qty,
   a.distinct_items_sold,
   (SELECT AVG(total_net_profit) FROM agg) AS avg_net_profit_all
FROM agg a
WHERE a.total_net_profit > (SELECT AVG(total_net_profit) FROM agg) * 1.2
  AND a.total_inventory_qty > 1000
  AND a.distinct_items_sold >= 5
ORDER BY a.total_net_profit DESC
LIMIT 100
