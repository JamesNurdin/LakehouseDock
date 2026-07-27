WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_returning_addr_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        d.d_date,
        d.d_fy_week_seq,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_call_center_sk IN (7, 14, 20)
      AND cr.cr_fee BETWEEN 20 AND 80
      AND d.d_fy_week_seq BETWEEN 10 AND 20
      AND d.d_current_day = 'N'
      AND r.r_reason_desc LIKE '%product%'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_reason_sk = cr.cr_reason_sk
            AND cr2.cr_net_loss > cr.cr_net_loss
      )
)
SELECT
    r_reason_desc,
    d_fy_week_seq,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    COUNT(*) AS returns_cnt,
    MIN(d_date) AS first_return_date,
    MAX(d_date) AS last_return_date
FROM filtered_returns
GROUP BY r_reason_desc, d_fy_week_seq
HAVING SUM(cr_net_loss) > 1000
   AND COUNT(*) >= 10
ORDER BY total_net_loss DESC
