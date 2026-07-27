WITH store_item_sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        ss.ss_item_sk,
        i.i_product_name,
        i.i_class,
        ss.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_sold_date_sk
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_class = 'shirts'
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND s.s_state = 'CA'
)
SELECT
    sis.s_store_name,
    SUM(sis.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT sis.ss_customer_sk) AS distinct_customers,
    RANK() OVER (ORDER BY SUM(sis.ss_net_paid) DESC) AS store_sales_rank,
    CASE
        WHEN SUM(sis.ss_net_paid) > 100000 THEN 'High'
        ELSE 'Medium'
    END AS sales_category,
    (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS avg_overall_net_paid
FROM store_item_sales sis
WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = sis.ss_item_sk
      AND inv.inv_quantity_on_hand > 500
)
GROUP BY sis.s_store_name
ORDER BY total_net_paid DESC
LIMIT 100
