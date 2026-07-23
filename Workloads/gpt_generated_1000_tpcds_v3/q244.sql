WITH sales_returns AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        ib.ib_income_band_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(CASE WHEN cs.cs_coupon_amt > 500 THEN 1 ELSE 0 END) AS high_coupon_orders
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 40000
    GROUP BY d.d_year, w.w_warehouse_name, ib.ib_income_band_sk
)
SELECT
    d_year,
    AVG(total_sales) AS avg_sales,
    AVG(total_profit) AS avg_profit,
    AVG(total_profit / NULLIF(total_sales, 0)) AS avg_profit_margin,
    SUM(high_coupon_orders) AS total_high_coupon_orders,
    CASE
        WHEN AVG(total_profit / NULLIF(total_sales, 0)) > 0.2 THEN 'High'
        WHEN AVG(total_profit / NULLIF(total_sales, 0)) > 0.1 THEN 'Medium'
        ELSE 'Low'
    END AS overall_profit_margin_category
FROM sales_returns
GROUP BY d_year
HAVING AVG(total_sales) > 50000
ORDER BY avg_profit_margin DESC
