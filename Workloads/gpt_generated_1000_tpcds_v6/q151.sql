WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sales_year,
        hd.hd_income_band_sk,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_promo_start.d_date_sk
    WHERE d_sold.d_year = 2001
      AND hd.hd_income_band_sk BETWEEN 5 AND 15
      AND p.p_channel_radio = 'N'
    GROUP BY
        d_sold.d_year,
        hd.hd_income_band_sk,
        i.i_category,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END
)
SELECT
    sales_year,
    hd_income_band_sk,
    i_category,
    total_sales,
    total_profit,
    order_count,
    promo_type,
    total_sales / NULLIF(order_count, 0) AS avg_sales_per_order,
    CASE WHEN total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM sales_agg
WHERE total_sales > 10000
  AND total_sales / NULLIF(order_count, 0) > 50
ORDER BY total_sales DESC
LIMIT 100
