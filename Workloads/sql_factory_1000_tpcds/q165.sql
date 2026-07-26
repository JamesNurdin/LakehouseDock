WITH daily_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date,
        ws.ws_web_page_sk AS web_page_id,
        ws.ws_promo_sk AS promo_sk,
        SUM(ws.ws_net_paid_inc_tax) AS daily_gross_paid,
        MAX(ws.ws_net_paid) AS max_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_page_sk, ws.ws_promo_sk
)
SELECT
    d.sale_date,
    d.web_page_id,
    d.daily_gross_paid,
    d.max_net_paid,
    LAG(d.daily_gross_paid, 1) OVER (PARTITION BY d.web_page_id ORDER BY d.sale_date) AS prev_day_gross,
    CASE WHEN d.daily_gross_paid > COALESCE(LAG(d.daily_gross_paid) OVER (PARTITION BY d.web_page_id ORDER BY d.sale_date), 0) THEN 'Increase' ELSE 'Decrease' END AS trend,
    COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
    CASE
        WHEN d.daily_gross_paid > 12000 THEN 'High'
        WHEN d.daily_gross_paid BETWEEN 6000 AND 12000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_tier
FROM daily_sales d
LEFT JOIN promotion p ON d.promo_sk = p.p_promo_sk
ORDER BY d.sale_date, d.web_page_id
