WITH sales_by_store_year AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d_sold.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    WHERE cs.cs_ext_sales_price > 5000
      AND d_sold.d_qoy = 2
      AND s.s_company_name = 'Unknown'
      AND d_ship.d_current_month = 'Y'
    GROUP BY s.s_store_sk, s.s_store_name, d_sold.d_year
)
SELECT
    s_store_name,
    year,
    total_sales,
    total_profit,
    order_count,
    CASE WHEN total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS sales_rank
FROM sales_by_store_year
ORDER BY year DESC, sales_rank ASC
LIMIT 100
