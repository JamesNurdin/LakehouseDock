WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_ship_mode_sk,
        cr.cr_returned_time_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_hdemo_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_refunded_cash,
        wr.wr_order_number,
        wr.wr_web_page_sk,
        t.t_shift,
        sm.sm_ship_mode_id,
        sm.sm_code,
        ca.ca_state,
        ca.ca_suite_number,
        hd.hd_income_band_sk,
        wp.wp_char_count
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_shift = 'first'
      AND sm.sm_code = 'AIR'
      AND ca.ca_suite_number = 'Suite 180'
      AND hd.hd_income_band_sk = 5
      AND wr.wr_refunded_cash > 500.00
      AND wp.wp_char_count BETWEEN 1000 AND 5000
)
SELECT
    sm_id,
    shift,
    state,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    AVG(wr_return_amt) AS avg_web_return_amount,
    COUNT(DISTINCT cr_order_number) AS distinct_order_cnt,
    SUM(CASE WHEN cr_net_loss > 100 THEN cr_return_amount ELSE 0 END) AS high_loss_return_amount,
    SUM(related_web_returns) AS total_related_web_returns
FROM (
    SELECT
        sm.sm_ship_mode_id AS sm_id,
        t.t_shift AS shift,
        ca.ca_state AS state,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        wr.wr_return_amt,
        wr.wr_order_number,
        -- lateral subquery counting other web returns for the same order number
        l.related_web_returns
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS related_web_returns
        FROM web_returns wr2
        WHERE wr2.wr_order_number = cr.cr_order_number
    ) AS l
    WHERE t.t_shift = 'first'
      AND sm.sm_code = 'AIR'
      AND ca.ca_suite_number = 'Suite 180'
      AND hd.hd_income_band_sk = 5
      AND wr.wr_refunded_cash > 500.00
      AND wp.wp_char_count BETWEEN 1000 AND 5000
) sub
GROUP BY GROUPING SETS (
    (sm_id, shift, state),
    (sm_id, shift),
    (state),
    ()
)
ORDER BY total_catalog_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
