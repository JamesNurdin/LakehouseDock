WITH
ss_data AS (
    SELECT
        ss.ss_sold_date_sk,
        d_ss.d_year AS sales_year,
        d_ss.d_month_seq,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ib_ss.ib_lower_bound,
        ib_ss.ib_upper_bound,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d_ss
      ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN household_demographics hd_ss
      ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib_ss
      ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
),
wr_data AS (
    SELECT
        wr.wr_returned_date_sk,
        d_wr_ret.d_year AS return_year,
        wr.wr_net_loss,
        wr.wr_order_number,
        ib_refunded.ib_lower_bound AS refunded_lb,
        ib_refunded.ib_upper_bound AS refunded_ub,
        ib_returning.ib_lower_bound AS returning_lb,
        ib_returning.ib_upper_bound AS returning_ub
    FROM web_returns wr
    JOIN date_dim d_wr_ret
      ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    JOIN household_demographics hd_refunded
      ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN income_band ib_refunded
      ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
    JOIN household_demographics hd_returning
      ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib_returning
      ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
),
cc_data AS (
    SELECT
        cc.cc_division,
        cc.cc_division_name,
        d_cc_closed.d_year AS closed_year,
        d_cc_open.d_year AS open_year
    FROM call_center cc
    JOIN date_dim d_cc_closed
      ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
      ON cc.cc_open_date_sk = d_cc_open.d_date_sk
),
cp_data AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_number,
        d_cp_start.d_year AS start_year,
        d_cp_end.d_year AS end_year
    FROM catalog_page cp
    JOIN date_dim d_cp_start
      ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
      ON cp.cp_end_date_sk = d_cp_end.d_date_sk
)
SELECT
    ss.sales_year,
    cp.cp_department,
    CAST(ss.ib_lower_bound AS varchar) || '-' || CAST(ss.ib_upper_bound AS varchar) AS income_band_range,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
    MIN(cc.cc_division_name) AS division_name
FROM ss_data ss
JOIN wr_data wr
  ON ss.sales_year = wr.return_year
JOIN cp_data cp
  ON ss.sales_year = cp.start_year
JOIN cc_data cc
  ON ss.sales_year = cc.closed_year
GROUP BY
    ss.sales_year,
    cp.cp_department,
    ss.ib_lower_bound,
    ss.ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
