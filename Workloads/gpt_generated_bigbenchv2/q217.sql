WITH customer_store_spend AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity * i.i_price) AS spend,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_customer_id
),
ranked_customers AS (
    SELECT
        cs.ss_store_id,
        cs.ss_customer_id,
        cs.spend,
        cs.quantity,
        RANK() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.spend DESC) AS spend_rank
    FROM customer_store_spend cs
)
SELECT
    rc.ss_store_id,
    s.s_store_name,
    rc.ss_customer_id,
    c.c_name,
    rc.spend,
    rc.quantity,
    rc.spend_rank
FROM ranked_customers rc
JOIN stores s ON rc.ss_store_id = s.s_store_id
JOIN customers c ON rc.ss_customer_id = c.c_customer_id
WHERE rc.spend_rank <= 5
ORDER BY rc.ss_store_id, rc.spend_rank
