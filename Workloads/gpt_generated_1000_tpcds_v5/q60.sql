WITH joined_data AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_number,
        hd.hd_buy_potential,
        sr.sr_store_sk,
        sr.sr_store_credit,
        sr.sr_refunded_cash,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_fee,
        cr.cr_returned_date_sk,
        hd.hd_vehicle_count
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_type = 'PROMO'
      AND cp.cp_catalog_number BETWEEN 100 AND 200
      AND sr.sr_store_sk IN (826, 956)
      AND sr.sr_store_credit > 10
      AND cr.cr_fee >= 20
      AND hd.hd_vehicle_count >= 1
),
agg AS (
    SELECT
        cp_department,
        hd_buy_potential,
        COUNT(*) AS txn_count,
        SUM(sr_store_credit) AS total_store_credit,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(sr_net_loss + cr_net_loss) AS total_net_loss,
        SUM(sr_store_credit + cr_return_amount) AS total_revenue
    FROM joined_data
    GROUP BY cp_department, hd_buy_potential
)
SELECT
    cp_department,
    hd_buy_potential,
    txn_count,
    total_store_credit,
    total_catalog_return_amount,
    total_net_loss,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
