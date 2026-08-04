WITH base AS (
    SELECT
        cc.cc_name,
        p.p_promo_name,
        i.i_brand,
        r.r_reason_desc,
        i.i_item_sk,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        ss.ss_ticket_number,
        cr.cr_return_amount,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                         AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
                         AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    FULL OUTER JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
                                 AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
                                 AND wr.wr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND p.p_purpose = 'Unknown'
      AND i.i_color = 'Red'
      AND ss.ss_sales_price > 50
      AND cr.cr_return_amount < 5000
      AND sm.sm_carrier = 'UPS'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2001-12-31'
      AND EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_return_amt > 200
      )
)
SELECT
    cc_name,
    p_promo_name,
    i_brand,
    r_reason_desc,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_returns,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    AVG(cr_return_amount) AS avg_return_amount,
    MAX(wr_return_amt) AS max_web_return,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = base.i_item_sk
    ) AS item_total_return_amount
FROM base
GROUP BY
    cc_name,
    p_promo_name,
    i_brand,
    r_reason_desc,
    i_item_sk
ORDER BY total_sales DESC
OFFSET 10
LIMIT 100
