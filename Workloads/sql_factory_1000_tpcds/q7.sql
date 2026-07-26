WITH daily_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date,
        ws.ws_web_page_sk AS web_page_id,
        ws.ws_promo_sk AS promo_sk,
        SUM(ws.ws_net_paid) AS daily_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_page_sk, ws.ws_promo_sk
)
SELECT
    d.sale_date,
    d.web_page_id,
    d.daily_net_paid,
    AVG(d.daily_net_paid) OVER (
        PARTITION BY d.web_page_id
        ORDER BY d.sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7d,
    RANK() OVER (PARTITION BY d.sale_date ORDER BY d.daily_net_paid DESC) AS daily_page_rank,
    COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
    CASE
        WHEN d.daily_net_paid > 10000 THEN 'High'
        WHEN d.daily_net_paid BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM daily_sales d
LEFT JOIN promotion p
    ON d.promo_sk = p.p_promo_sk
