WITH sold_dates AS (
    SELECT d.d_date_sk,
           d.d_year,
           d.d_month_seq
    FROM   date_dim d
    WHERE  d.d_year = 2001
)
SELECT
    'Promotional' AS sales_type,
    p.p_promo_name AS promo_name,
    d.d_year,
    d.d_month_seq AS month,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM   web_sales ws
JOIN   sold_dates d      ON ws.ws_sold_date_sk = d.d_date_sk
JOIN   promotion p       ON ws.ws_promo_sk = p.p_promo_sk
WHERE  ws.ws_ext_sales_price > 50
GROUP BY
    p.p_promo_name,
    d.d_year,
    d.d_month_seq

UNION ALL

SELECT
    'Non-Promo' AS sales_type,
    w.w_warehouse_name AS promo_name,
    d.d_year,
    d.d_month_seq AS month,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM   web_sales ws
JOIN   sold_dates d          ON ws.ws_sold_date_sk = d.d_date_sk
LEFT   JOIN promotion p       ON ws.ws_promo_sk = p.p_promo_sk
JOIN   warehouse w           ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE  p.p_promo_sk IS NULL
GROUP BY
    w.w_warehouse_name,
    d.d_year,
    d.d_month_seq

ORDER BY
    sales_type,
    total_sales DESC,
    month
LIMIT 100
