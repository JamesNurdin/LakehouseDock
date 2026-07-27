WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_customer_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_reversed_charge,
        wr.wr_account_credit,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100
      AND wr.wr_return_quantity >= 1
      AND EXISTS (
            SELECT 1
            FROM reason r_sub
            WHERE r_sub.r_reason_sk = wr.wr_reason_sk
              AND r_sub.r_reason_desc LIKE '%price%'
        )
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.r_reason_desc,
    td.t_sub_shift,
    COALESCE(wp.wp_type, 'unknown') AS page_type,
    SUM(fr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    COUNT(DISTINCT fr.wr_return_quantity) AS distinct_qty_cnt,
    AVG(fr.wr_return_tax) AS avg_return_tax,
    MIN(fr.wr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(fr.wr_return_amt_inc_tax) AS max_return_inc_tax
FROM filtered_returns fr
JOIN customer c
    ON fr.wr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN reason r
    ON fr.wr_reason_sk = r.r_reason_sk
JOIN time_dim td
    ON fr.wr_returned_time_sk = td.t_time_sk
LEFT JOIN web_page wp
    ON fr.wr_web_page_sk = wp.wp_web_page_sk
       AND wp.wp_type = 'product'
WHERE c.c_preferred_cust_flag = 'Y'
  AND hd.hd_income_band_sk = 5
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.r_reason_desc,
    td.t_sub_shift,
    COALESCE(wp.wp_type, 'unknown')
ORDER BY total_return_amount DESC
LIMIT 100
