WITH filtered AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_order_number,
        cc.cc_name,
        cc.cc_state,
        cc.cc_mkt_id,
        d.d_year,
        d.d_month_seq,
        d.d_qoy,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND cc.cc_mkt_id IN (3, 4, 5)
      AND cc.cc_state = 'CA'
      AND hd.hd_income_band_sk = 5
      AND wr.wr_return_amt > 100.00
      AND wr.wr_return_quantity >= 1
)
SELECT
    cc_name,
    d_year,
    d_month_seq,
    hd_buy_potential,
    hd_vehicle_count,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wr_order_number) AS distinct_orders,
    MAX(wr_return_ship_cost) AS max_ship_cost,
    MIN(wr_refunded_cash) AS min_refunded_cash
FROM filtered
GROUP BY
    cc_name,
    d_year,
    d_month_seq,
    hd_buy_potential,
    hd_vehicle_count
ORDER BY total_return_amount DESC
LIMIT 100
