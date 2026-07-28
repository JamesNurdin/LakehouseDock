WITH store_return_stats AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_fee) AS total_fee,
        AVG(i.i_current_price) AS avg_price,
        COUNT(*) AS ret_count
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND i.i_current_price > 5
      AND hd.hd_buy_potential = '1001-5000'
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
)
SELECT
    store_id,
    AVG(total_return_amt) AS avg_monthly_return_amt
FROM store_return_stats
GROUP BY store_id
HAVING AVG(total_return_amt) > 5000
ORDER BY avg_monthly_return_amt DESC
