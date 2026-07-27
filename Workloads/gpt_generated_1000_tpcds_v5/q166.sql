WITH sales_returns_agg AS (
    SELECT
        p.p_promo_name            AS promo_name,
        w.web_name                AS web_name,
        d_common.d_year           AS year,
        SUM(cs.cs_ext_sales_price)    AS total_sales,
        SUM(sr.sr_return_amt)         AS total_returns,
        AVG(cs.cs_ext_discount_amt)   AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_common
        ON cs.cs_sold_date_sk = d_common.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_common.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d_common.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN date_dim d_web_close
        ON w.web_close_date_sk = d_web_close.d_date_sk
    WHERE d_common.d_year = 2001
      AND d_common.d_month_seq IN (10, 13)
      AND cs.cs_ext_discount_amt > 1000
      AND p.p_channel_event = 'N'
      AND w.web_state = 'CA'
    GROUP BY p.p_promo_name, w.web_name, d_common.d_year
)
SELECT
    promo_name,
    web_name,
    year,
    total_sales,
    total_returns,
    avg_discount,
    total_sales - total_returns AS net_sales,
    CASE WHEN total_returns = 0 THEN NULL ELSE total_sales / total_returns END AS sales_return_ratio
FROM sales_returns_agg
WHERE total_sales > 50000
ORDER BY sales_return_ratio DESC NULLS LAST
LIMIT 100
