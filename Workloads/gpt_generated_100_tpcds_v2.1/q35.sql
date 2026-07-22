WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_order_number,
        d_sale.d_year,
        d_sale.d_month_seq,
        p.p_promo_name,
        p.p_channel_email,
        p.p_discount_active,
        cc.cc_name,
        cc.cc_manager,
        s.s_store_name,
        s.s_manager,
        s.s_city,
        s.s_state,
        s.s_country
    FROM catalog_sales cs
    JOIN date_dim d_sale
        ON cs.cs_sold_date_sk = d_sale.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sale.d_date_sk
)
SELECT
    d_year,
    d_month_seq,
    CONCAT(s_city, ', ', s_state) AS location,
    p_promo_name,
    CASE WHEN regexp_like(p_promo_name, '(?i)discount') THEN 'Contains Discount' ELSE 'Other' END AS promo_type,
    CASE WHEN p_channel_email = 'Y' THEN 'Email' ELSE 'No Email' END AS email_channel,
    SUBSTR(s_manager, 1, 3) AS manager_initials,
    SUM(cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    AVG(cs_net_profit) AS avg_net_profit,
    CASE WHEN SUM(cs_net_profit) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
FROM sales_data
WHERE
    p_discount_active = 'N'
    AND s_manager LIKE '%Thomas%'
GROUP BY
    d_year,
    d_month_seq,
    CONCAT(s_city, ', ', s_state),
    p_promo_name,
    CASE WHEN regexp_like(p_promo_name, '(?i)discount') THEN 'Contains Discount' ELSE 'Other' END,
    CASE WHEN p_channel_email = 'Y' THEN 'Email' ELSE 'No Email' END,
    SUBSTR(s_manager, 1, 3)
ORDER BY total_net_profit DESC
LIMIT 100
