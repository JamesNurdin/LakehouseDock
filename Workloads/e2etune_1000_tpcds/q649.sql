WITH monthly_promo_sales AS (
    SELECT 
        d.d_year,
        d.d_moy,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE p.p_cost > 10000
      AND cs.cs_net_profit > 0
    GROUP BY d.d_year, d.d_moy, p.p_promo_name
)
SELECT 
    d_year,
    d_moy,
    p_promo_name,
    total_profit,
    total_sales,
    avg_discount,
    unique_customers,
    RANK() OVER (PARTITION BY d_year, d_moy ORDER BY total_profit DESC) AS profit_rank
FROM monthly_promo_sales
ORDER BY d_year, d_moy, profit_rank
