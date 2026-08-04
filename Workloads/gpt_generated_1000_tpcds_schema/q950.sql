WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
intersect_items AS (
    SELECT ss_item_sk
    FROM sampled_sales
    WHERE ss_quantity > 1
    INTERSECT
    SELECT cr_item_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 1
),
sales_enriched AS (
    SELECT
        ss.*, 
        td.t_meal_time,
        td.t_time_sk,
        p.p_promo_id,
        p.p_channel_catalog,
        ca.ca_city,
        ca.ca_state,
        LAG(ss.ss_ext_sales_price) OVER (
            PARTITION BY p.p_promo_id
            ORDER BY td.t_time_sk
        ) AS lag_sales_price
    FROM sampled_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        td.t_meal_time = 'dinner'
        AND p.p_channel_catalog = 'N'
        AND ca.ca_state = 'CA'
        AND ss.ss_ext_sales_price > 5000
        AND ss.ss_item_sk IN (SELECT ss_item_sk FROM intersect_items)
)
SELECT
    se.p_promo_id,
    se.t_meal_time,
    se.ca_city,
    SUM(se.ss_ext_sales_price) AS total_sales,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT se.ss_ticket_number) AS distinct_tickets,
    SUM(CASE WHEN se.lag_sales_price IS NOT NULL THEN 1 ELSE 0 END) AS rows_with_lag,
    (SELECT COUNT(*) FROM catalog_returns WHERE cr_return_quantity > 0) AS total_return_rows
FROM sales_enriched se
JOIN catalog_returns cr
    ON se.ss_item_sk = cr.cr_item_sk
    AND cr.cr_returned_time_sk = se.t_time_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = se.ss_item_sk
      AND cr2.cr_return_amount > 100
)
GROUP BY
    se.p_promo_id,
    se.t_meal_time,
    se.ca_city
ORDER BY total_sales DESC
LIMIT 100
