WITH cs_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk
)
SELECT
    d_sold.d_year,
    w.w_warehouse_name,
    w.w_city,
    ib_bill.ib_lower_bound,
    ib_bill.ib_upper_bound,
    cs_agg.total_sales,
    cs_agg.total_profit,
    CASE WHEN cs_agg.total_profit > 0 THEN 'PROFITABLE' ELSE 'LOSS' END AS profit_category,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = d_sold.d_date_sk
    ) AS total_returns_for_date,
    COUNT(*) AS rows_in_group
FROM cs_agg
JOIN date_dim d_sold
    ON cs_agg.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs_agg.cs_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
FULL OUTER JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN household_demographics hd_bill
    ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
GROUP BY
    d_sold.d_year,
    w.w_warehouse_name,
    w.w_city,
    ib_bill.ib_lower_bound,
    ib_bill.ib_upper_bound,
    cs_agg.total_sales,
    cs_agg.total_profit,
    CASE WHEN cs_agg.total_profit > 0 THEN 'PROFITABLE' ELSE 'LOSS' END,
    d_sold.d_date_sk
HAVING
    cs_agg.total_sales > 100000
ORDER BY
    cs_agg.total_sales DESC
LIMIT 100
