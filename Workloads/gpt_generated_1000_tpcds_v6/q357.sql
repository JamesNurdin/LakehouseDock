WITH distinct_income AS (
    SELECT DISTINCT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound >= 100000
),
catalog_agg AS (
    SELECT
        d_sold.d_year AS year,
        ib.ib_income_band_sk AS income_band_sk,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_fee,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib
        ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    JOIN distinct_income di
        ON ib.ib_income_band_sk = di.ib_income_band_sk
    WHERE d_sold.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND cr.cr_call_center_sk IN (1, 7, 38)
      AND cr.cr_fee > 20
      AND ib.ib_upper_bound <= 150000
      AND cs.cs_quantity >= 2
      AND cs.cs_ship_mode_sk = 2
    GROUP BY d_sold.d_year, ib.ib_income_band_sk
),
web_agg AS (
    SELECT
        d_ret.d_year AS year,
        ib.ib_income_band_sk AS income_band_sk,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib
        ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    JOIN distinct_income di
        ON ib.ib_income_band_sk = di.ib_income_band_sk
    WHERE d_ret.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND wr.wr_fee > 20
      AND ib.ib_lower_bound >= 100000
      AND wr.wr_return_quantity >= 1
      AND wr.wr_returned_time_sk BETWEEN 1000 AND 2000
      AND wr.wr_web_page_sk = 5
    GROUP BY d_ret.d_year, ib.ib_income_band_sk
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
LIMIT 100
