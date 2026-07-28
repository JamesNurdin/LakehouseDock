WITH base_agg AS (
    SELECT
        wp.wp_type,
        r.r_reason_desc,
        hd.hd_buy_potential,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_qty
    FROM tpcds.web_returns wr
    JOIN tpcds.customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wp.wp_type IN ('general', 'order')
      AND wp.wp_autogen_flag = 'Y'
      AND wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
    GROUP BY wp.wp_type, r.r_reason_desc, hd.hd_buy_potential
)
SELECT
    CASE WHEN grouping(wp_type) = 1 THEN 'ALL_TYPES'   ELSE wp_type END AS wp_type,
    CASE WHEN grouping(r_reason_desc) = 1 THEN 'ALL_REASONS' ELSE r_reason_desc END AS r_reason_desc,
    hd_buy_potential,
    SUM(total_return_amt) AS sum_return_amt,
    SUM(total_qty)        AS sum_qty,
    AVG(total_return_amt) AS avg_return_amt_per_group,
    (SELECT SUM(wr2.wr_return_amt) FROM tpcds.web_returns wr2) AS overall_return_amt
FROM base_agg
GROUP BY GROUPING SETS (
    (wp_type, r_reason_desc, hd_buy_potential),
    (wp_type, hd_buy_potential),
    (r_reason_desc, hd_buy_potential),
    (hd_buy_potential)
)
HAVING SUM(total_return_amt) > 500
ORDER BY wp_type ASC, r_reason_desc ASC
