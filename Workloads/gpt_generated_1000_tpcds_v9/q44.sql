WITH latest_promo AS (
    SELECT i.i_item_sk,
           p.p_promo_sk,
           p.p_promo_name,
           p.p_start_date_sk,
           p.p_end_date_sk
    FROM item i
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_sk,
               p2.p_promo_name,
               p2.p_start_date_sk,
               p2.p_end_date_sk
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
        ORDER BY p2.p_start_date_sk DESC
        LIMIT 1
    ) AS p
),
inventory_stock AS (
    SELECT i.i_item_sk,
           inv.inv_quantity_on_hand,
           w.w_warehouse_name
    FROM inventory inv
    FULL OUTER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
),
store_agg AS (
    SELECT i.i_item_sk,
           i.i_category,
           SUM(ss.ss_ext_sales_price) AS store_sales_amt,
           SUM(ss.ss_net_profit) AS store_net_profit,
           COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_item_sk, i.i_category
),
web_agg AS (
    SELECT i.i_item_sk,
           i.i_category,
           SUM(ws.ws_ext_sales_price) AS web_sales_amt,
           SUM(ws.ws_net_profit) AS web_net_profit,
           COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_item_sk, i.i_category
),
combined_sales AS (
    SELECT i_item_sk,
           i_category,
           store_sales_amt,
           NULL AS web_sales_amt,
           store_net_profit,
           NULL AS web_net_profit,
           store_txn_cnt,
           NULL AS web_txn_cnt
    FROM store_agg
    UNION ALL
    SELECT i_item_sk,
           i_category,
           NULL AS store_sales_amt,
           web_sales_amt,
           NULL AS store_net_profit,
           web_net_profit,
           NULL AS store_txn_cnt,
           web_txn_cnt
    FROM web_agg
)
SELECT cs.i_item_sk,
       i.i_product_name,
       cs.i_category,
       cs.store_sales_amt,
       cs.web_sales_amt,
       cs.store_net_profit,
       cs.web_net_profit,
       cs.store_txn_cnt,
       cs.web_txn_cnt,
       lp.p_promo_name,
       inv_stock.inv_quantity_on_hand,
       inv_stock.w_warehouse_name,
       ROW_NUMBER() OVER (
           PARTITION BY cs.i_category
           ORDER BY COALESCE(cs.store_sales_amt, 0) + COALESCE(cs.web_sales_amt, 0) DESC
       ) AS category_rank
FROM combined_sales cs
JOIN item i ON cs.i_item_sk = i.i_item_sk
LEFT JOIN latest_promo lp ON i.i_item_sk = lp.i_item_sk
LEFT JOIN inventory_stock inv_stock ON i.i_item_sk = inv_stock.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = cs.i_item_sk
      AND ss2.ss_net_profit > 500
)
ORDER BY cs.i_category, category_rank
LIMIT 100
