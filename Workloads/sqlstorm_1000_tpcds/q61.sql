WITH sales_union AS (
    SELECT
        cs_sold_date_sk AS sold_date_sk,
        cs_sold_time_sk AS sold_time_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        cs_call_center_sk AS call_center_sk,
        cs_promo_sk AS promo_sk,
        cs_quantity,
        cs_net_paid,
        cs_net_paid_inc_tax,
        cs_net_profit,
        'catalog' AS channel,
        cs_order_number AS order_number,
        cs_ship_mode_sk,
        cs_warehouse_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        NULL,
        ss_promo_sk,
        ss_quantity,
        ss_net_paid,
        ss_net_paid_inc_tax,
        ss_net_profit,
        'store_sales' AS channel,
        ss_ticket_number,
        ss_promo_sk,
        ss_store_sk
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        NULL,
        ws_promo_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_paid_inc_tax,
        ws_net_profit,
        'web' AS channel,
        ws_order_number,
        ws_ship_mode_sk,
        ws_warehouse_sk
    FROM web_sales
),
date_cte AS (
    SELECT
        d_date_sk,
        d_date,
        d_year,
        d_month_seq,
        d_week_seq,
        CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END AS is_holiday,
        COALESCE(d_quarter_name, 'UNKNOWN') AS quarter_name
    FROM date_dim
),
promo_cte AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        p_discount_active,
        CASE WHEN p_discount_active = 'Y' THEN p_cost * -1 ELSE 0 END AS discount_amount
    FROM promotion
),
call_center_latest AS (
    SELECT
        cc_call_center_sk,
        cc_manager,
        cc_name,
        cc_gmt_offset,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_sk ORDER BY cc_rec_end_date DESC NULLS LAST) AS rn
    FROM call_center
    WHERE cc_rec_end_date IS NOT NULL
),
item_cte AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        i_category,
        i_color,
        CASE WHEN i_current_price = 0 THEN NULL ELSE ROUND(i_current_price * 1.03, 2) END AS inflated_price
    FROM item
    WHERE i_current_price IS NOT NULL
)
SELECT
    d.d_year,
    d.quarter_name,
    s.channel,
    COALESCE(cc.cc_manager, 'UNKNOWN MANAGER') AS manager_name,
    COALESCE(p.p_promo_name, 'NO PROMO') AS promo_name,
    COUNT(DISTINCT s.order_number) AS orders,
    SUM(s.cs_net_profit) AS total_profit,
    SUM(s.cs_quantity) AS total_quantity,
    AVG(s.cs_net_paid) AS avg_paid,
    MAX(s.cs_net_paid) FILTER (WHERE s.cs_quantity > 0) AS max_paid,
    MIN(s.cs_net_paid) FILTER (WHERE s.cs_quantity > 0) AS min_paid,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN s.cs_net_paid * 0.9 ELSE s.cs_net_paid END) AS adjusted_paid,
    array_join(array_agg(DISTINCT i.i_brand || ':' || i.i_category), ',') AS brands
FROM sales_union s
JOIN date_cte d ON s.sold_date_sk = d.d_date_sk
LEFT JOIN promo_cte p ON s.promo_sk = p.p_promo_sk
LEFT JOIN call_center_latest cc ON s.call_center_sk = cc.cc_call_center_sk AND cc.rn = 1
LEFT JOIN item_cte i ON s.item_sk = i.i_item_sk
GROUP BY
    d.d_year,
    d.quarter_name,
    s.channel,
    COALESCE(cc.cc_manager, 'UNKNOWN MANAGER'),
    COALESCE(p.p_promo_name, 'NO PROMO')
