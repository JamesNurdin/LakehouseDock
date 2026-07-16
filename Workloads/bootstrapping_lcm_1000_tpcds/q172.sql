WITH store_month_category AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        sm.sm_type,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost + cr.cr_fee) AS total_charges
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        sm.sm_type
)
SELECT
    smc.s_store_id,
    smc.s_store_name,
    smc.s_state,
    smc.d_year,
    smc.d_month_seq,
    smc.i_category,
    smc.i_brand,
    smc.sm_type,
    smc.return_count,
    smc.total_return_amount,
    smc.avg_net_loss,
    smc.total_fee,
    smc.total_charges,
    ROW_NUMBER() OVER (PARTITION BY smc.s_store_id ORDER BY smc.total_return_amount DESC) AS store_monthly_return_rank
FROM store_month_category smc
WHERE smc.total_return_amount > 5000
ORDER BY smc.total_return_amount DESC
LIMIT 100
