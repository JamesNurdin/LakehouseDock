WITH sales_with_price AS (
    SELECT
        ss.ss_transaction_id,
        ss.ss_customer_id,
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        ss.ss_ts,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        (ss.ss_quantity * i.i_price) AS revenue,
        (ss.ss_quantity * (i.i_price - i.i_comp_price)) AS profit
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
),
customer_category_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        swp.i_category_id,
        swp.i_category_name,
        SUM(swp.revenue) AS total_revenue,
        SUM(swp.profit) AS total_profit,
        COUNT(DISTINCT swp.ss_transaction_id) AS transaction_count
    FROM sales_with_price swp
    JOIN customers c
        ON swp.ss_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name, swp.i_category_id, swp.i_category_name
)
SELECT
    ccs.c_name,
    ccs.i_category_name,
    ccs.total_revenue,
    ccs.total_profit,
    ccs.transaction_count,
    ROW_NUMBER() OVER (PARTITION BY ccs.i_category_name ORDER BY ccs.total_revenue DESC) AS rank_in_category
FROM customer_category_sales ccs
WHERE ccs.total_revenue > 500
ORDER BY ccs.i_category_name, rank_in_category
LIMIT 20
