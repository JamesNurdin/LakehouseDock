WITH sales_by_item AS (
    SELECT
        i.i_category AS category,
        i.i_brand   AS brand,
        i.i_product_name AS product_name,
        SUM(ss.ss_quantity)           AS total_quantity,
        SUM(ss.ss_ext_sales_price)    AS total_sales,
        SUM(ss.ss_ext_discount_amt)   AS total_discount,
        SUM(ss.ss_net_paid)           AS total_net_paid,
        SUM(ss.ss_net_profit)         AS total_profit,
        AVG(ss.ss_ext_discount_amt)   AS avg_discount_per_sale
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_product_name
)
SELECT
    category,
    brand,
    product_name,
    total_quantity,
    total_sales,
    total_discount,
    total_net_paid,
    total_profit,
    avg_discount_per_sale,
    total_profit / NULLIF(total_quantity, 0) AS profit_per_unit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_sales DESC) AS brand_sales_rank
FROM sales_by_item
WHERE total_quantity > 0
ORDER BY total_profit DESC
LIMIT 100
