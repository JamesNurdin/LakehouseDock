WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        d.d_year,
        i.i_category,
        i.i_class,
        hd.hd_income_band_sk,
        p.p_discount_active,
        t.t_hour,
        t.t_meal_time
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_class IN ('hockey', 'pop')
      AND ss.ss_quantity > 1
      AND hd.hd_income_band_sk BETWEEN 3 AND 5
      AND p.p_discount_active = 'Y'
)
SELECT
    sb.d_year,
    sb.i_category,
    sb.i_class,
    COUNT(*) AS transaction_cnt,
    SUM(sb.ss_ext_sales_price) AS total_sales,
    SUM(sb.ss_ext_discount_amt) AS total_discount,
    CASE
        WHEN SUM(sb.ss_ext_discount_amt) / NULLIF(SUM(sb.ss_ext_sales_price), 0) > 0.10 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_level,
    COALESCE(wp.wp_type, 'NoPage') AS page_type,
    RANK() OVER (PARTITION BY sb.d_year ORDER BY SUM(sb.ss_ext_sales_price) DESC) AS sales_rank
FROM sales_base sb
LEFT JOIN web_page wp
    ON sb.ss_sold_date_sk = wp.wp_creation_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = sb.ss_sold_date_sk
GROUP BY
    sb.d_year,
    sb.i_category,
    sb.i_class,
    wp.wp_type
HAVING SUM(sb.ss_ext_sales_price) > 10000
ORDER BY sb.d_year, sales_rank
LIMIT 100
