WITH cr_base AS (
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
        cr.cr_ship_mode_sk,
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
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
),
sr_base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_amt > 0
)
SELECT
    agg.cc_call_center_id,
    agg.s_store_id,
    agg.i_category,
    agg.d_year,
    agg.distinct_orders,
    agg.sum_catalog_return_amount,
    agg.sum_store_return_amount,
    agg.total_return_amount,
    agg.avg_catalog_return_qty,
    agg.max_store_return_qty,
    SUM(agg.total_return_amount) OVER (PARTITION BY agg.cc_call_center_id ORDER BY agg.d_year) AS running_total_by_cc
FROM (
    SELECT
        cc.cc_call_center_id,
        s.s_store_id,
        i.i_category,
        d_cr.d_year,
        COUNT(DISTINCT cr_base.cr_order_number) AS distinct_orders,
        SUM(cr_base.cr_return_amount) AS sum_catalog_return_amount,
        SUM(sr_base.sr_return_amt) AS sum_store_return_amount,
        SUM(cr_base.cr_return_amount) + SUM(sr_base.sr_return_amt) AS total_return_amount,
        AVG(cr_base.cr_return_quantity) AS avg_catalog_return_qty,
        MAX(sr_base.sr_return_quantity) AS max_store_return_qty
    FROM cr_base
    JOIN date_dim d_cr          ON cr_base.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr          ON cr_base.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i                ON cr_base.cr_item_sk = i.i_item_sk
    JOIN call_center cc        ON cr_base.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm          ON cr_base.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_refund   ON cr_base.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund  ON cr_base.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_refund       ON cr_base.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_demographics cd_return   ON cr_base.cr_returning_cdemo_sk = cd_return.cd_demo_sk
    JOIN household_demographics hd_return  ON cr_base.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN customer_address ca_return       ON cr_base.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN sr_base               ON cr_base.cr_item_sk = sr_base.sr_item_sk
    JOIN date_dim d_sr         ON sr_base.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr         ON sr_base.sr_return_time_sk = t_sr.t_time_sk
    JOIN store s               ON sr_base.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd_store   ON sr_base.sr_cdemo_sk = cd_store.cd_demo_sk
    JOIN household_demographics hd_store  ON sr_base.sr_hdemo_sk = hd_store.hd_demo_sk
    JOIN customer_address ca_store        ON sr_base.sr_addr_sk = ca_store.ca_address_sk
    JOIN inventory inv          ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv        ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE
        d_cr.d_year = 2001
        AND d_cr.d_month_seq BETWEEN 1200 AND 1220
        AND sm.sm_code = 'AIR'
        AND cc.cc_state = 'CA'
        AND s.s_state = 'CA'
        AND cd_return.cd_education_status = 'College'
        AND i.i_current_price > 50
    GROUP BY
        cc.cc_call_center_id,
        s.s_store_id,
        i.i_category,
        d_cr.d_year
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
