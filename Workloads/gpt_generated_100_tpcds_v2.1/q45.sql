WITH sales_returns_monthly AS (
    SELECT
        c.c_customer_id,
        d_sales.d_year AS year,
        d_sales.d_month_seq AS month,
        SUM(cs.cs_ext_sales_price) AS monthly_sales,
        SUM(cs.cs_net_profit) AS monthly_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS monthly_returns,
        SUM(COALESCE(sr.sr_fee, 0)) AS monthly_return_fees
    FROM
        customer c
        JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
        LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        LEFT JOIN date_dim d_returns ON sr.sr_returned_date_sk = d_returns.d_date_sk
        LEFT JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
        LEFT JOIN date_dim d_page_end ON cp.cp_end_date_sk = d_page_end.d_date_sk
        LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
        LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE
        d_sales.d_year = 2001
        AND d_sales.d_month_seq BETWEEN 1 AND 12
        AND cs.cs_quantity >= 2
        AND p.p_discount_active = 'N'
        AND cp.cp_type = 'catalog'
        AND (sr.sr_return_amt IS NULL OR sr.sr_return_amt >= 0)
    GROUP BY
        c.c_customer_id,
        d_sales.d_year,
        d_sales.d_month_seq
)
SELECT
    year,
    AVG(monthly_sales) AS avg_monthly_sales,
    AVG(monthly_profit) AS avg_monthly_profit,
    AVG(monthly_returns) AS avg_monthly_returns,
    AVG(monthly_return_fees) AS avg_monthly_return_fees
FROM sales_returns_monthly
WHERE monthly_sales > 500
GROUP BY year
ORDER BY avg_monthly_profit DESC
LIMIT 100
