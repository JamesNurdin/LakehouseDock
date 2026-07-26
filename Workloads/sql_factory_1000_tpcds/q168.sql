WITH daily_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date,
        ws.ws_web_page_sk AS web_page_id,
        ws.ws_promo_sk AS promo_sk,
        SUM(ws.ws_ext_sales_price) AS daily_ext_sales,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_page_sk, ws.ws_promo_sk
)
SELECT
    d.sale_date,
    d.web_page_id,
    d.daily_ext_sales,
    d.avg_quantity,
    AVG(d.daily_ext_sales) OVER (
        PARTITION BY d.web_page_id
        ORDER BY d.sale_date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) AS moving_avg_4d,
    RANK() OVER (PARTITION BY d.sale_date ORDER BY d.avg_quantity DESC) AS quantity_rank,
    COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
    CASE
        WHEN d.daily_ext_sales > 20000 THEN 'High'
        WHEN d.daily_ext_sales BETWEEN 10000 AND 20000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM daily_sales d
LEFT JOIN promotion p ON d.promo_sk = p.p_promo_sk
WHERE d.daily_ext_sales IS NOT NULL
ORDER BY d.sale_date, d.web_page_id
