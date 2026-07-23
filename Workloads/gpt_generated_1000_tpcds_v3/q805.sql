WITH monthly_aggregates AS (
    SELECT
        d_year,
        d_month_seq,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_ext_discount_amt) AS avg_discount,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    JOIN date_dim
        ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_date >= DATE '1998-01-01'
      AND date_dim.d_date < DATE '1998-04-01'
      AND date_dim.d_current_day = 'N'
      AND store_sales.ss_ext_sales_price > 1000.00
      AND store_sales.ss_quantity >= 2
    GROUP BY d_year, d_month_seq
)
SELECT
    d_year,
    AVG(total_sales) AS avg_monthly_sales,
    SUM(total_profit) AS total_yearly_profit,
    AVG(avg_discount) AS avg_monthly_discount,
    SUM(total_quantity) AS total_yearly_quantity
FROM monthly_aggregates
GROUP BY d_year
HAVING SUM(total_profit) > 10000
   AND AVG(total_sales) > 5000
ORDER BY avg_monthly_sales DESC
LIMIT 100
