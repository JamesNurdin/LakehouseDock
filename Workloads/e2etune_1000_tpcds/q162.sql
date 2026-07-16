WITH agg AS (
    SELECT
        s.s_store_name,
        p.p_promo_name,
        cp.cp_type,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON p.p_promo_id = cp.cp_catalog_page_id
    JOIN inventory i ON i.inv_item_sk = ss.ss_item_sk AND i.inv_date_sk = ss.ss_sold_date_sk
    WHERE p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND i.inv_quantity_on_hand > 500
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY s.s_store_name, p.p_promo_name, cp.cp_type
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    agg.s_store_name,
    agg.p_promo_name,
    agg.cp_type,
    agg.total_net_profit,
    agg.total_sales,
    agg.avg_discount_amt,
    agg.total_inventory_on_hand,
    agg.txn_count,
    RANK() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 10
