WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_current_month,
        wr.wr_return_amt_inc_tax,
        wr.wr_account_credit,
        wr.wr_return_quantity,
        r.r_reason_desc AS r_reason_desc,
        c_ref.c_customer_id AS refunded_customer_id,
        c_ret.c_customer_id AS returning_customer_id,
        c_ref.c_salutation,
        ca_ref.ca_state,
        i.inv_quantity_on_hand,
        wp.wp_type
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_current_month = 'Y'
      AND wr.wr_return_amt_inc_tax > 500
      AND wr.wr_account_credit >= 100
      AND c_ref.c_salutation = 'Mr.'
      AND ca_ref.ca_state = 'CA'
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        refunded_customer_id,
        returning_customer_id,
        r_reason_desc,
        SUM(wr_return_amt_inc_tax) AS total_return_amt,
        SUM(wr_return_quantity) AS total_return_qty
    FROM base
    GROUP BY
        d_year,
        d_month_seq,
        refunded_customer_id,
        returning_customer_id,
        r_reason_desc
)
SELECT
    d_year,
    d_month_seq,
    refunded_customer_id,
    returning_customer_id,
    r_reason_desc,
    total_return_amt,
    total_return_qty,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rank_by_year,
    ROW_NUMBER() OVER (PARTITION BY refunded_customer_id ORDER BY total_return_amt DESC) AS rn_per_customer
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
