WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS order_number,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS order_number,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    SUM(combined_sales.net_paid) AS total_net_paid,
    SUM(combined_sales.net_profit) AS total_net_profit,
    COUNT(DISTINCT combined_sales.order_number) AS distinct_orders
FROM combined_sales
JOIN date_dim d ON combined_sales.sold_date_sk = d.d_date_sk
JOIN item i ON combined_sales.item_sk = i.i_item_sk
WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category
ORDER BY
    d.d_year,
    d.d_month_seq,
    i.i_category
