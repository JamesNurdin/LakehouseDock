WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451545 AND 2451900
    GROUP BY ss_store_sk, ss_sold_date_sk
)
SELECT
    d.d_date,
    s.s_store_name,
    s.s_state,
    ib.ib_upper_bound,
    ss.total_sales,
    ss.total_profit,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d.d_date) AS rn,
    LAG(ss.total_sales) OVER (PARTITION BY s.s_store_id ORDER BY d.d_date) AS prev_day_sales
FROM ss_agg ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND ib.ib_upper_bound > 50000
    AND inv.inv_quantity_on_hand > 0
    AND hd.hd_vehicle_count >= 2
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = d.d_date_sk
          AND wr2.wr_return_amt > 200
    )
GROUP BY
    d.d_date,
    s.s_store_name,
    s.s_state,
    ib.ib_upper_bound,
    ss.total_sales,
    ss.total_profit,
    s.s_store_id
ORDER BY d.d_date ASC
LIMIT 100
