WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
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
        cr.cr_order_number,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        t.t_hour,
        sm.sm_type,
        w.w_state,
        w.w_city,
        s.s_state,
        s.s_gmt_offset,
        p.p_discount_active
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    WHERE d.d_year = 2001
      AND w.w_city = 'Oak Ninth'
      AND s.s_gmt_offset = -8.00
      AND t.t_hour BETWEEN 12 AND 14
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        d_year,
        w_state,
        sm_type,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        AVG(cr_return_tax) AS avg_return_tax,
        MIN(cr_return_quantity) AS min_quantity,
        MAX(cr_return_amt_inc_tax) AS max_amount_inc_tax
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, w_state, sm_type),
        (d_year, w_state),
        (d_year),
        ()
    )
)
SELECT
    d_year,
    w_state,
    sm_type,
    CASE WHEN total_return_amount > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
    total_return_amount,
    distinct_orders,
    avg_return_tax,
    min_quantity,
    max_amount_inc_tax
FROM agg
ORDER BY d_year DESC, w_state, sm_type
LIMIT 100
