WITH store_sales_agg AS (
    SELECT
        date_trunc('month', d.d_date) AS month_start,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_net_paid_inc_tax) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_discount_amt) AS discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        SUM(CASE WHEN ss.ss_promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year >= 2020
    GROUP BY date_trunc('month', d.d_date), i.i_category, i.i_brand
),
catalog_sales_agg AS (
    SELECT
        date_trunc('month', d.d_date) AS month_start,
        i.i_category,
        i.i_brand,
        SUM(cs.cs_net_paid_inc_tax) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_ext_discount_amt) AS discount,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(CASE WHEN cs.cs_promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year >= 2020
    GROUP BY date_trunc('month', d.d_date), i.i_category, i.i_brand
),
web_sales_agg AS (
    SELECT
        date_trunc('month', d.d_date) AS month_start,
        i.i_category,
        i.i_brand,
        SUM(ws.ws_net_paid_inc_tax) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_discount_amt) AS discount,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(CASE WHEN ws.ws_promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year >= 2020
    GROUP BY date_trunc('month', d.d_date), i.i_category, i.i_brand
),
combined_sales AS (
    SELECT month_start, i_category, i_brand, net_paid, net_profit, discount, orders, promo_orders FROM store_sales_agg
    UNION ALL
    SELECT month_start, i_category, i_brand, net_paid, net_profit, discount, orders, promo_orders FROM catalog_sales_agg
    UNION ALL
    SELECT month_start, i_category, i_brand, net_paid, net_profit, discount, orders, promo_orders FROM web_sales_agg
)
SELECT
    month_start,
    i_category,
    i_brand,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(discount) AS total_discount,
    SUM(orders) AS total_orders,
    SUM(promo_orders) AS total_promo_orders,
    CASE WHEN SUM(orders) > 0 THEN CAST(SUM(promo_orders) AS DOUBLE) / SUM(orders) ELSE 0 END AS promo_order_rate,
    CASE WHEN SUM(orders) > 0 THEN SUM(discount) / SUM(orders) ELSE 0 END AS avg_discount_per_order
FROM combined_sales
GROUP BY month_start, i_category, i_brand
ORDER BY month_start, i_category, i_brand
