/*
Goal: Identify the highest web return amounts per state for the year 2001, enriched with customer address, income band, promotion details and inventory on the return date, and rank the returns both within each state and overall.
*/
WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        d.d_date,
        d.d_year,
        d.d_date_sk,
        t.t_hour,
        ca_ret.ca_state,
        ca_ret.ca_country,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        p.p_discount_active,
        CASE
            WHEN ib.ib_upper_bound > 100000 THEN 'High'
            ELSE 'Mid/Low'
        END AS income_group
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN income_band ib
        ON hd_ret.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
        AND p.p_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound > 50000
      AND p.p_discount_active = 'Y'
      AND wr.wr_return_amt_inc_tax > 500
)
SELECT
    b.d_date,
    b.ca_state,
    b.income_group,
    b.p_promo_name,
    b.wr_return_amt_inc_tax,
    b.wr_return_quantity,
    COALESCE(i.inv_quantity_on_hand, 0) AS inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.wr_return_amt_inc_tax DESC) AS rn_state,
    RANK() OVER (ORDER BY b.wr_return_amt_inc_tax DESC) AS overall_rank
FROM base b
LEFT JOIN inventory i
    ON i.inv_date_sk = b.d_date_sk
ORDER BY overall_rank ASC, b.ca_state
LIMIT 100
