WITH sales_promo_agg AS (
    SELECT
        d.d_year AS year,
        p.p_channel_email AS channel_email,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND p.p_discount_active = 'Y'
      AND p.p_channel_tv = 'Y'
    GROUP BY d.d_year, p.p_channel_email
)
SELECT
    a.year,
    a.channel_email,
    AVG(a.total_sales) AS avg_sales_per_channel,
    (SELECT MAX(cs2.cs_ext_discount_amt) FROM catalog_sales cs2) AS max_discount_overall
FROM sales_promo_agg a
WHERE EXISTS (
        SELECT 1
        FROM promotion p_sub
        WHERE p_sub.p_channel_email = a.channel_email
          AND p_sub.p_response_target > 0
    )
GROUP BY a.year, a.channel_email
HAVING AVG(a.total_sales) > 5000
ORDER BY avg_sales_per_channel DESC
LIMIT 100
