WITH sales_ts AS (
    SELECT
        ss_transaction_id,
        ss_customer_id,
        ss_store_id,
        ss_item_id,
        ss_quantity,
        CAST(ss_ts AS timestamp) AS ts
    FROM store_sales
)
SELECT
    s.s_store_name,
    date_trunc('hour', st.ts) AS hour_ts,
    sum(st.ss_quantity) AS total_quantity
FROM sales_ts st
JOIN stores s
    ON st.ss_store_id = s.s_store_id
WHERE st.ss_quantity > 0
GROUP BY
    s.s_store_name,
    date_trunc('hour', st.ts)
ORDER BY total_quantity DESC
LIMIT 10
