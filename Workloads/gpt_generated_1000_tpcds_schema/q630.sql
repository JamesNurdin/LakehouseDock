WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 0
),

sales_without_returns AS (
    SELECT cs_order_number
    FROM sampled_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
),

item_promotions AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           p.p_promo_name,
           p.p_discount_active,
           regexp_extract(i.i_item_desc, '(\\d{3})') AS extracted_code
    FROM item i
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}\\d{3}')
),

sales_with_time AS (
    SELECT cs.cs_order_number,
           cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           lt.t_time,
           lt.t_am_pm,
           lt.t_hour,
           lt.t_minute,
           lt.t_second
    FROM sampled_sales cs
    LEFT JOIN LATERAL (
        SELECT t.t_time, t.t_am_pm, t.t_hour, t.t_minute, t.t_second
        FROM time_dim t
        WHERE t.t_time_sk = cs.cs_sold_time_sk
        ORDER BY t.t_time DESC
        LIMIT 1
    ) lt ON true
    WHERE cs.cs_quantity > (
        SELECT MAX(cs_quantity)
        FROM catalog_sales
        WHERE cs_sold_date_sk = cs.cs_sold_date_sk
    )
)

SELECT
    ip.i_item_sk,
    ip.i_product_name,
    ip.p_promo_name,
    ip.extracted_code,
    SUM(swt.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT swt.cs_order_number) AS orders_count,
    MAX(swt.t_time) AS latest_time,
    MAX(SUBSTRING(CAST(swt.t_time AS VARCHAR) FROM 1 FOR 3)) AS max_time_prefix,
    CASE
        WHEN regexp_like(ip.i_product_name, '^.*PRO.*$') THEN 'ContainsPRO'
        ELSE 'Other'
    END AS product_category_flag
FROM sales_with_time swt
JOIN item_promotions ip ON swt.cs_item_sk = ip.i_item_sk
WHERE ip.p_discount_active = 'Y'
  AND ip.i_product_name LIKE '%' || 'CO' || '%'
  AND swt.t_am_pm = 'PM'
  AND swt.cs_order_number IN (SELECT cs_order_number FROM sales_without_returns)
  AND swt.cs_net_paid > (SELECT AVG(cs_net_paid) FROM catalog_sales)
GROUP BY ip.i_item_sk, ip.i_product_name, ip.p_promo_name, ip.extracted_code
ORDER BY total_net_paid DESC
LIMIT 100
