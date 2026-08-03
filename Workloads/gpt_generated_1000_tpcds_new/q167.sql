WITH sales_filtered AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_coupon_amt
    FROM store_sales ss
    WHERE ss.ss_store_sk IN (
        SELECT s.s_store_sk
        FROM store s
        WHERE s.s_state = 'CA'
    )
)
SELECT
    s.s_store_name,
    d.d_quarter_name,
    i.i_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_quantity) AS total_units_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    CONCAT(i.i_brand, ' ', i.i_category) AS brand_category,
    REGEXP_EXTRACT(i.i_item_id, '[0-9]+') AS item_numeric_id,
    CASE
        WHEN REGEXP_LIKE(i.i_product_name, '\\d') THEN 'ContainsNumber'
        ELSE 'NoNumber'
    END AS product_name_flag
FROM sales_filtered ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    d.d_year = 1998
    AND s.s_store_name LIKE 'Store%'
    AND REGEXP_LIKE(i.i_product_name, '^.*[A-Z]{3}.*$')
    AND i.i_product_name LIKE '%CO%'
GROUP BY
    s.s_store_name,
    d.d_quarter_name,
    i.i_category,
    CONCAT(i.i_brand, ' ', i.i_category),
    REGEXP_EXTRACT(i.i_item_id, '[0-9]+'),
    CASE
        WHEN REGEXP_LIKE(i.i_product_name, '\\d') THEN 'ContainsNumber'
        ELSE 'NoNumber'
    END
ORDER BY total_profit DESC
LIMIT 100
