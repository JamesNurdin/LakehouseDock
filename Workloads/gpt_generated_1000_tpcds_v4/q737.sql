WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_details,
        REGEXP_EXTRACT(p.p_channel_details, '(fair|common|teachers)', 1) AS extracted_keyword,
        CONCAT(p.p_promo_name, ' - ', REGEXP_EXTRACT(p.p_channel_details, '(fair|common|teachers)', 1)) AS promo_label,
        SUBSTR(p.p_promo_name, 1, 5) AS promo_prefix
    FROM promotion p
    WHERE REGEXP_LIKE(p.p_channel_details, '(fair|common|teachers)')
      AND p.p_channel_radio = 'N'
),
sales_with_returns AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cr.cr_return_amount
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    WHERE cs.cs_ext_sales_price > 0
)
SELECT
    pf.p_promo_id,
    pf.promo_label,
    pf.promo_prefix,
    td.t_hour,
    SUM(swr.cs_ext_sales_price) AS total_sales_amount,
    SUM(COALESCE(swr.cr_return_amount, 0)) AS total_return_amount,
    COUNT(DISTINCT swr.cs_order_number) AS distinct_orders
FROM sales_with_returns swr
JOIN promo_filtered pf
    ON swr.cs_promo_sk = pf.p_promo_sk
JOIN time_dim td
    ON swr.cs_sold_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
GROUP BY
    pf.p_promo_id,
    pf.promo_label,
    pf.promo_prefix,
    td.t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
