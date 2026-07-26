WITH customer_item_store_agg AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        i.i_item_id,
        i.i_product_name,
        COUNT(DISTINCT s.s_store_id) AS distinct_store_count,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY c.c_customer_id, c.c_customer_sk, i.i_item_id, i.i_product_name
    HAVING COUNT(DISTINCT s.s_store_id) >= 2
)
SELECT
    c_customer_id,
    i_item_id,
    i_product_name,
    distinct_store_count,
    total_quantity,
    total_spent,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY distinct_store_count DESC, total_spent DESC) AS purchase_rank,
    CASE
        WHEN distinct_store_count >= 3 THEN 'Frequent Multi-Store Buyer'
        WHEN distinct_store_count = 2 THEN 'Dual-Store Buyer'
        ELSE 'Single-Store Buyer'
    END AS buyer_type
FROM customer_item_store_agg
ORDER BY c_customer_id, purchase_rank
LIMIT 30
