WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_list_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sd.d_date AS sold_date
    FROM store_sales ss
    JOIN date_dim sd ON ss.ss_sold_date_sk = sd.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim start_date ON p.p_start_date_sk = start_date.d_date_sk
    JOIN date_dim end_date ON p.p_end_date_sk = end_date.d_date_sk
    WHERE sd.d_date BETWEEN start_date.d_date AND end_date.d_date
)
SELECT
    date_format(sold_date, '%Y-%m') AS year_month,
    COUNT(*) AS sales_count,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_ext_discount_amt) AS total_discount,
    AVG(ss_ext_discount_amt / NULLIF(ss_ext_list_price, 0)) AS avg_discount_ratio,
    COUNT(DISTINCT ss_promo_sk) AS distinct_promotions
FROM filtered_sales
GROUP BY date_format(sold_date, '%Y-%m')
ORDER BY year_month
