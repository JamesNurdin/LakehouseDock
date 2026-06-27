WITH unified_sales AS (
    SELECT
        cs_sold_date_sk AS sold_date_sk,
        cs_item_sk AS item_sk,
        cs_promo_sk AS promo_sk,
        cs_ext_sales_price AS ext_sales_price,
        cs_ext_tax AS ext_tax,
        cs_net_profit AS net_profit,
        'catalog' AS sales_channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_promo_sk AS promo_sk,
        ss_ext_sales_price AS ext_sales_price,
        ss_ext_tax AS ext_tax,
        ss_net_profit AS net_profit,
        'store' AS sales_channel
    FROM store_sales
)

SELECT
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    us.sales_channel,
    COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
    SUM(us.ext_sales_price) AS total_sales,
    SUM(us.ext_tax) AS total_tax,
    SUM(us.net_profit) AS total_profit,
    COUNT(*) AS transaction_cnt,
    CASE
        WHEN d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date THEN 1
        ELSE 0
    END AS promo_active_flag
FROM unified_sales us
JOIN date_dim d_sold
    ON us.sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON us.item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON us.promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
LEFT JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    us.sales_channel,
    COALESCE(p.p_promo_name, 'No Promotion'),
    CASE
        WHEN d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date THEN 1
        ELSE 0
    END
ORDER BY
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    us.sales_channel,
    total_sales DESC
