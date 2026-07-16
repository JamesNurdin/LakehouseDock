WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt
    FROM store_sales ss
)
SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    COUNT(DISTINCT sales.ss_customer_sk) AS unique_customers,
    SUM(sales.ss_quantity) AS total_quantity,
    SUM(sales.ss_ext_sales_price) AS total_sales,
    SUM(sales.ss_net_profit) AS total_profit,
    AVG(sales.ss_ext_discount_amt) AS avg_discount,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sales.ss_ext_sales_price) DESC) AS sales_rank
FROM sales
JOIN date_dim d ON sales.ss_sold_date_sk = d.d_date_sk
JOIN store s ON sales.ss_store_sk = s.s_store_sk
JOIN item i ON sales.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON sales.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_year,
    s.s_state,
    i.i_category,
    i.i_brand,
    p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
