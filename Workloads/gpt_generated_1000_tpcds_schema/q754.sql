WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
),

ticket_numbers_with_returns AS (
    SELECT sr.sr_ticket_number AS ticket_number
    FROM store_returns sr
    WHERE sr.sr_refunded_cash > 100
),

ticket_numbers_with_web AS (
    SELECT wr.wr_order_number AS ticket_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 200
),

common_tickets AS (
    SELECT ticket_number FROM ticket_numbers_with_returns
    INTERSECT
    SELECT ticket_number FROM ticket_numbers_with_web
),

sales_detail AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        d.d_year,
        d.d_date_sk,
        s.s_state,
        r.r_reason_desc,
        sm.sm_type,
        w.w_warehouse_name,
        cr.cr_return_amount,
        wr.wr_return_amt,
        sr.sr_refunded_cash
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE ss.ss_net_paid_inc_tax > 500
      AND s.s_state = 'CA'
      AND cd.cd_purchase_estimate >= 3000
      AND ss.ss_ticket_number IN (SELECT ticket_number FROM common_tickets)
),

final_enriched AS (
    SELECT
        sd.*, 
        lr.web_return_cnt,
        CASE WHEN sd.sr_refunded_cash > 150 THEN 'High Refund' ELSE 'Low Refund' END AS refund_category
    FROM sales_detail sd
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS web_return_cnt
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = sd.d_date_sk
    ) lr ON true
)
SELECT
    fe.s_state,
    fe.d_year,
    fe.refund_category,
    COUNT(DISTINCT fe.ss_ticket_number) AS sales_cnt,
    SUM(fe.ss_net_paid_inc_tax) AS total_net_paid,
    AVG(fe.ss_ext_sales_price) AS avg_ext_sales,
    MIN(fe.web_return_cnt) AS min_web_returns
FROM final_enriched fe
GROUP BY fe.s_state, fe.d_year, fe.refund_category
HAVING COUNT(*) > 5
ORDER BY total_net_paid DESC
LIMIT 100
