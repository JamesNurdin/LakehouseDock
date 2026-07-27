WITH base_join AS (
    SELECT
        cr.cr_refunded_hdemo_sk,
        cr.cr_store_credit,
        cr.cr_refunded_cash,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        sr.sr_reversed_charge,
        ss.ss_ext_sales_price,
        ss.ss_coupon_amt,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_store_credit < 200
        AND sr.sr_reversed_charge > 100
        AND sr.sr_return_amt_inc_tax BETWEEN 500 AND 2000
        AND ss.ss_coupon_amt > 0
),
agg1 AS (
    SELECT
        cr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(cr_net_loss) AS total_cr_net_loss,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(ss_ext_sales_price) AS total_sales_price,
        AVG(ss_coupon_amt) AS avg_coupon_amt
    FROM base_join
    GROUP BY cr_refunded_hdemo_sk
),
high_metrics AS (
    SELECT hd_demo_sk FROM agg1 WHERE total_cr_net_loss > 1000
    UNION ALL
    SELECT hd_demo_sk FROM agg1 WHERE total_sales_price > 5000
),
final_agg AS (
    SELECT
        COUNT(DISTINCT hm.hd_demo_sk) AS households_count,
        SUM(a.total_cr_net_loss) AS sum_net_loss,
        AVG(a.total_sales_price) AS avg_sales_price
    FROM agg1 a
    JOIN high_metrics hm
        ON a.hd_demo_sk = hm.hd_demo_sk
    WHERE a.total_return_qty > 5
        AND a.total_cr_net_loss > (SELECT AVG(total_cr_net_loss) FROM agg1)
        AND EXISTS (
            SELECT 1 FROM store_sales ss3
            WHERE ss3.ss_hdemo_sk = a.hd_demo_sk
                AND ss3.ss_coupon_amt > 500
        )
)
SELECT *
FROM final_agg
LIMIT 100
