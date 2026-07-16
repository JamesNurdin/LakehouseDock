WITH sales_by_store_item AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_quantity) AS total_quantity,
        sum(ss.ss_ext_discount_amt) AS total_discount,
        sum(ss.ss_net_profit) AS total_profit,
        avg(ss.ss_ext_discount_amt) AS avg_discount,
        sum(ss.ss_ext_sales_price) - sum(ss.ss_ext_discount_amt) AS net_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, i.i_item_id, i.i_product_name, i.i_category
),
ranked_sales AS (
    SELECT
        s_store_id,
        s_store_name,
        s_state,
        i_item_id,
        i_product_name,
        i_category,
        total_sales,
        total_quantity,
        avg_discount,
        total_profit,
        net_sales,
        row_number() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS rn
    FROM sales_by_store_item
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    i_item_id,
    i_product_name,
    i_category,
    total_sales,
    total_quantity,
    avg_discount,
    total_profit,
    total_profit / nullif(total_sales, 0) AS profit_margin,
    net_sales
FROM ranked_sales
WHERE rn <= 5
ORDER BY s_store_id, total_sales DESC
