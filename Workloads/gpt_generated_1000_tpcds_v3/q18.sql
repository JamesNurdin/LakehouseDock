WITH base AS (
    SELECT
        c.cc_call_center_id AS cc_id,
        c.cc_state AS cc_state,
        c.cc_gmt_offset AS cc_gmt_offset,
        r.r_reason_sk AS reason_sk,
        r.r_reason_id AS reason_id,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_store_credit AS cr_store_credit,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        wr.wr_refunded_cash AS wr_refunded_cash,
        wr.wr_fee AS wr_fee,
        wp.wp_web_page_id AS wp_id,
        wp.wp_char_count AS wp_char_count,
        wp.wp_rec_end_date AS wp_rec_end_date
    FROM call_center c
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = c.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.cc_state = 'CA'
      AND c.cc_gmt_offset BETWEEN -8.00 AND -5.00
      AND cr.cr_return_amount > 1000.00
      AND cr.cr_store_credit < 500.00
      AND wr.wr_refunded_cash > 500.00
      AND wr.wr_fee BETWEEN 20.00 AND 100.00
      AND wp.wp_char_count > 2000
      AND wp.wp_rec_end_date >= DATE '2000-01-01'
)
SELECT
    cc_id,
    cc_state,
    reason_id,
    wp_id,
    total_return_qty,
    total_return_amount,
    total_net_loss,
    CASE
        WHEN total_net_loss > 10000 THEN 'High'
        WHEN total_net_loss > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    avg_reason_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cc_id ORDER BY total_net_loss DESC) AS rn
FROM (
    SELECT
        cc_id,
        cc_state,
        reason_id,
        wp_id,
        reason_sk,
        SUM(cr_return_quantity + wr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount + wr_return_amt) AS total_return_amount,
        SUM(cr_net_loss + wr_net_loss) AS total_net_loss,
        (SELECT AVG(cr_sub.cr_return_amount)
         FROM catalog_returns cr_sub
         WHERE cr_sub.cr_reason_sk = reason_sk) AS avg_reason_return_amount
    FROM base
    GROUP BY cc_id, cc_state, reason_id, wp_id, reason_sk
) agg
ORDER BY total_net_loss DESC, rn
LIMIT 100
