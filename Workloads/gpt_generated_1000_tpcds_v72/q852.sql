WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd_bill.cd_gender AS gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_quantity) AS avg_qty,
        COUNT(*) AS sales_cnt,
        CASE
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_flag
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    WHERE
        d.d_year = 2002
        AND cs.cs_quantity >= 2
        AND cs.cs_ext_ship_cost > 500
        AND hd_bill.hd_income_band_sk IN (10, 16, 18)
        AND hd_bill.hd_vehicle_count >= 0
        AND cd_bill.cd_marital_status = 'M'
        AND cs.cs_ext_sales_price > 100
        AND NOT EXISTS (
            SELECT 1
            FROM customer_demographics cd_ship
            WHERE cd_ship.cd_demo_sk = cs.cs_ship_cdemo_sk
              AND cd_ship.cd_credit_rating = 'Poor'
        )
    GROUP BY d.d_year, d.d_month_seq, cd_bill.cd_gender
)
SELECT
    gender,
    AVG(total_sales) AS avg_total_sales,
    SUM(sales_cnt) AS total_transactions,
    SUM(CASE WHEN profit_flag = 'Profit' THEN total_sales ELSE 0 END) AS profit_sales,
    SUM(CASE WHEN profit_flag = 'Loss' THEN total_sales ELSE 0 END) AS loss_sales
FROM sales_agg
GROUP BY gender
HAVING AVG(total_sales) > 500
ORDER BY avg_total_sales DESC
