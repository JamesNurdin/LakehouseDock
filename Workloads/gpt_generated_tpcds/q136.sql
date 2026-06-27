WITH promo_sales AS (
    SELECT
        cs.cs_promo_sk,
        p.p_promo_name,
        p.p_channel_email,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_quantity > 0
    GROUP BY cs.cs_promo_sk, p.p_promo_name, p.p_channel_email
)
SELECT
    cs_promo_sk,
    p_promo_name,
    p_channel_email,
    total_sales,
    total_discount,
    total_profit,
    sales_count,
    total_sales - total_discount AS net_sales,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM promo_sales
WHERE total_sales > 0
ORDER BY total_sales DESC
LIMIT 10
