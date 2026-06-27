/*
  Analytical query: top customers by total spend per store.
  - Joins store_sales to customers, items, and stores using the allowed join keys.
  - Calculates sales amount per transaction (quantity * price).
  - Aggregates per store‑customer pair (total spent, transaction count, distinct categories purchased).
  - Ranks customers within each store by total spend.
*/
WITH sales_detail AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        ss.ss_quantity * i.i_price AS sales_amount,
        i.i_category_name,
        c.c_name,
        s.s_store_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
store_customer_summary AS (
    SELECT
        sd.s_store_name,
        sd.c_name,
        SUM(sd.sales_amount) AS total_spent,
        COUNT(*) AS transaction_cnt,
        COUNT(DISTINCT sd.i_category_name) AS distinct_categories
    FROM sales_detail sd
    GROUP BY sd.s_store_name, sd.c_name
)
SELECT
    scs.s_store_name,
    scs.c_name,
    scs.total_spent,
    scs.transaction_cnt,
    scs.distinct_categories,
    ROW_NUMBER() OVER (PARTITION BY scs.s_store_name ORDER BY scs.total_spent DESC) AS rank_in_store
FROM store_customer_summary scs
WHERE scs.total_spent > 500
ORDER BY scs.s_store_name, rank_in_store
LIMIT 30
