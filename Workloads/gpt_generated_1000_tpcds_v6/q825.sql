WITH agg_returns AS (
    SELECT
        d_cc.d_year,
        cc.cc_name,
        hd_sr.hd_buy_potential,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
        CASE
            WHEN SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) > 5000 THEN 'HIGH'
            ELSE 'LOW'
        END AS return_level
    FROM call_center cc
    JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_cc.d_date_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_cc.d_date_sk
    JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    WHERE d_cc.d_quarter_seq = 12
      AND cc.cc_state = 'CA'
      AND hd_sr.hd_buy_potential = '>10000'
      AND wr.wr_fee > 20
    GROUP BY d_cc.d_year, cc.cc_name, hd_sr.hd_buy_potential
)
SELECT DISTINCT
    a.d_year,
    a.cc_name,
    a.hd_buy_potential,
    a.total_store_return_amt,
    a.total_web_return_amt,
    a.return_level,
    a.distinct_store_tickets,
    a.distinct_web_orders,
    RANK() OVER (PARTITION BY a.d_year ORDER BY (a.total_store_return_amt + a.total_web_return_amt) DESC) AS rank_by_total,
    SUM(a.total_store_return_amt + a.total_web_return_amt) OVER (PARTITION BY a.d_year ORDER BY a.cc_name ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt
FROM agg_returns a
WHERE (a.total_store_return_amt + a.total_web_return_amt) > 10000
ORDER BY a.d_year DESC, rank_by_total
LIMIT 100
