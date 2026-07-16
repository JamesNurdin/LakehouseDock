WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_promo_sk, ss.ss_sold_date_sk
)
SELECT
    d_sale.d_year,
    d_sale.d_month_seq,
    d_sale.d_date,
    s.s_store_name,
    s.s_state,
    d_closed.d_date AS store_closed_date,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    ws.web_name,
    ws.web_state,
    d_web_close.d_date AS web_close_date,
    sa.total_sales,
    sa.total_profit,
    sa.total_quantity,
    (sa.total_sales - sa.total_discount) AS net_sales,
    CASE
        WHEN d_sale.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date THEN 'Active'
        ELSE 'Inactive'
    END AS promo_status,
    CASE
        WHEN d_closed.d_date IS NULL OR d_sale.d_date < d_closed.d_date THEN 'Open'
        ELSE 'Closed'
    END AS store_status,
    CASE
        WHEN d_sale.d_date <= d_web_close.d_date THEN 'Online'
        ELSE 'Offline'
    END AS website_status,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY sa.total_sales DESC) AS store_sales_rank
FROM sales_agg sa
JOIN date_dim d_sale ON sa.ss_sold_date_sk = d_sale.d_date_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sale.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sale.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND sa.total_sales > 1000
ORDER BY net_sales DESC
LIMIT 100
