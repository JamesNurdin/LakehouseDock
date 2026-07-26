WITH daily_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date,
        ws.ws_web_page_sk AS web_page_id,
        ws.ws_promo_sk AS promo_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS daily_total_paid,
        COUNT(DISTINCT ws.ws_order_number) AS daily_orders
    FROM web_sales ws
    WHERE ws.ws_promo_sk IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_page_sk, ws.ws_promo_sk
)
SELECT
    d.sale_date,
    d.web_page_id,
    d.daily_total_paid,
    d.daily_orders,
    PERCENT_RANK() OVER (PARTITION BY d.web_page_id ORDER BY d.daily_total_paid) AS pct_rank,
    ROW_NUMBER() OVER (PARTITION BY d.sale_date ORDER BY d.daily_orders DESC) AS order_rank,
    COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
    CASE
        WHEN d.daily_total_paid > 18000 THEN 'High'
        WHEN d.daily_total_paid BETWEEN 9000 AND 18000 THEN 'Medium'
        ELSE 'Low'
    END AS performance_category
FROM daily_sales d
LEFT JOIN promotion p ON d.promo_sk = p.p_promo_sk
ORDER BY d.sale_date, d.web_page_id
