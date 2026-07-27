/*
Goal: Analyze catalog return performance by call center, item category and income band, applying several realistic filters, aggregating key return metrics, and computing a cumulative return amount per state using a window function.
*/
WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        i.i_category,
        i.i_size,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cr.cr_return_amount)          AS total_return_amount,
        AVG(cr.cr_return_amount)          AS avg_return_amount,
        SUM(cr.cr_net_loss)               AS total_net_loss
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    /* Refunded address (joined but not used in final select) */
    JOIN tpcds.customer_address ca_ref
      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    /* Returning address – used for a filter */
    JOIN tpcds.customer_address ca_ret
      ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    /* Refunded household demographics – used to reach income band */
    JOIN tpcds.household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    /* Returning household demographics – joined for completeness */
    JOIN tpcds.household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_size = 'large'
      AND i.i_category_id IN (2, 3, 6)
      AND cc.cc_state = 'CA'
      AND ca_ret.ca_state = 'TX'
      AND ib.ib_upper_bound <= 150000
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND EXISTS (
            SELECT 1
            FROM tpcds.item i2
            WHERE i2.i_item_sk = i.i_item_sk
              AND i2.i_current_price > 100
          )
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_state,
        i.i_category,
        i.i_size,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    *,
    SUM(total_return_amount) OVER (PARTITION BY cc_state ORDER BY total_return_amount DESC) AS cum_return_by_state
FROM base
ORDER BY total_return_amount DESC
LIMIT 100
