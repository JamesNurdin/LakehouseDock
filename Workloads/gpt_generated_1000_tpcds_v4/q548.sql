WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_ship_cost,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_quarter_name = '2002Q1'
      AND cr.cr_return_amount > 10
),
agg_returns AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        w.w_warehouse_name,
        sm.sm_type,
        cd.cd_credit_rating,
        ib.ib_lower_bound,
        SUM(fr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT fr.cr_order_number) AS distinct_orders
    FROM filtered_returns fr
    JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE sm.sm_type = 'AIR'
      AND cd.cd_credit_rating = 'Good'
      AND ib.ib_lower_bound >= 50000
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        w.w_warehouse_name,
        sm.sm_type,
        cd.cd_credit_rating,
        ib.ib_lower_bound
)
SELECT
    a.d_year,
    a.d_quarter_name,
    a.w_warehouse_name,
    a.sm_type,
    a.cd_credit_rating,
    a.ib_lower_bound,
    a.total_return_amount,
    a.distinct_orders,
    RANK() OVER (PARTITION BY a.d_year, a.d_quarter_name ORDER BY a.total_return_amount DESC) AS warehouse_return_rank
FROM agg_returns a
ORDER BY a.total_return_amount DESC
LIMIT 100
