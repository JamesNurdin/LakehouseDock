WITH joined_data AS (
    SELECT
        cr.cr_returning_customer_sk,
        c_ret.c_customer_id AS returning_customer_id,
        cr.cr_returned_date_sk,
        d_ret.d_date AS return_date,
        d_ret.d_year,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        i.i_item_id,
        i.i_current_price,
        cp.cp_catalog_page_id,
        w.w_warehouse_id,
        w.w_state,
        r.r_reason_desc,
        t.t_hour,
        hd_returning.hd_income_band_sk,
        ib_returning.ib_lower_bound,
        CASE WHEN cr.cr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS return_size
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib_returning ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
    -- Join the refunded side to satisfy "join all tables" requirement
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    -- Join catalog page start/end dates
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year = 2001
      AND i.i_current_price > 20.00
      AND t.t_hour BETWEEN 9 AND 17
      AND w.w_state = 'CA'
),
customer_returns AS (
    SELECT
        returning_customer_id,
        COUNT(*) AS num_returns,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(CASE WHEN return_size = 'Large' THEN 1 ELSE 0 END) AS large_returns,
        MAX(i_current_price) AS max_item_price,
        (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
    FROM joined_data
    GROUP BY returning_customer_id
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    returning_customer_id,
    num_returns,
    total_return_amount,
    avg_return_amount,
    large_returns,
    max_item_price,
    overall_avg_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS return_rank,
    CASE WHEN total_return_amount > overall_avg_return_amount * 2 THEN 'High' ELSE 'Normal' END AS return_category
FROM customer_returns
ORDER BY total_return_amount DESC
LIMIT 100
