WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        s.s_store_sk,
        s.s_county,
        d_sold.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND s.s_county = 'Levy County'
      AND d_sold.d_year = 2002
      AND cs.cs_quantity > 2
      AND cs.cs_net_paid_inc_tax > 100
      AND cs.cs_ext_sales_price > 500
    GROUP BY c.c_customer_sk, c.c_preferred_cust_flag, s.s_store_sk, s.s_county, d_sold.d_year
),
returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
      AND wr.wr_return_amt > 50
      AND wr.wr_return_ship_cost > 20
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT
    sa.c_customer_sk,
    sa.c_preferred_cust_flag,
    sa.s_store_sk,
    sa.s_county,
    sa.d_year,
    sa.total_sales,
    sa.total_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    ROUND((sa.total_profit - COALESCE(ra.total_loss, 0)) / NULLIF(sa.sales_count, 0), 2) AS profit_per_sale
FROM sales_agg sa
LEFT JOIN returns_agg ra ON ra.customer_sk = sa.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_refunded_customer_sk = sa.c_customer_sk
      AND wr2.wr_returned_date_sk = (
          SELECT d2.d_date_sk
          FROM date_dim d2
          WHERE d2.d_date = DATE '2002-12-31'
          LIMIT 1
      )
)
ORDER BY sa.total_sales DESC
LIMIT 100
