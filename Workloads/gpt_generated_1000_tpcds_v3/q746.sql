WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month_seq,
        hd_bill.hd_income_band_sk AS income_band,
        hd_bill.hd_buy_potential AS buy_potential,
        ws.web_state AS web_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        hd_bill.hd_income_band_sk,
        hd_bill.hd_buy_potential,
        ws.web_state
),
returns_agg AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        hd_refunded.hd_income_band_sk AS income_band,
        hd_refunded.hd_buy_potential AS buy_potential,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        hd_refunded.hd_income_band_sk,
        hd_refunded.hd_buy_potential
)
SELECT
    s.sale_year,
    s.sale_month_seq,
    s.income_band,
    s.buy_potential,
    s.web_state,
    s.total_sales,
    s.total_profit,
    s.distinct_orders,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.avg_return_amount, 0) AS avg_return_amount,
    COALESCE(r.distinct_return_orders, 0) AS distinct_return_orders,
    (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.sale_year = r.return_year
   AND s.sale_month_seq = r.return_month_seq
   AND s.income_band = r.income_band
   AND s.buy_potential = r.buy_potential
WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd_filter
    WHERE hd_filter.hd_demo_sk = s.income_band
      AND hd_filter.hd_vehicle_count > 0
)
ORDER BY s.total_sales DESC
LIMIT 100
