WITH base AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM
        tpcds.date_dim d
        JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
        JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
        JOIN tpcds.promotion p ON p.p_start_date_sk = d.d_date_sk
        JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_fy_year = 1910
        AND cc.cc_state = 'CA'
        AND cp.cp_type = 'A'
        AND p.p_channel_tv = 'N'
        AND ib.ib_lower_bound >= 50000
        AND cr.cr_return_amount > 100
        AND sm.sm_type = 'AIR'
        AND ws.web_state = 'CA'
    GROUP BY
        cc.cc_call_center_id,
        d.d_year,
        d.d_month_seq
)
SELECT
    cc_call_center_id,
    d_year,
    AVG(total_return_amount) AS avg_monthly_return_amount,
    AVG(total_net_loss) AS avg_monthly_net_loss,
    SUM(return_cnt) AS total_returns,
    AVG(total_promo_cost) AS avg_monthly_promo_cost
FROM base
GROUP BY
    cc_call_center_id,
    d_year
HAVING
    SUM(return_cnt) > 10
ORDER BY
    avg_monthly_net_loss DESC
LIMIT 100
