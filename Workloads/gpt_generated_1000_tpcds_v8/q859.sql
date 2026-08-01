WITH sampled_wr AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
),
cc_dates AS (
    SELECT
        cc.cc_call_center_id,
        d.d_date_sk AS cc_date_sk
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
),
store_dates AS (
    SELECT
        s.s_store_id,
        d.d_date_sk AS store_date_sk
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
),
joined_all AS (
    SELECT
        cc.cc_call_center_id,
        s.s_store_id,
        d.d_year,
        r.r_reason_desc,
        r.r_reason_id,
        ca.ca_state,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        ib.ib_lower_bound,
        p.p_promo_name,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY wr.wr_return_amt DESC) AS rn_state,
        la.amt_category
    FROM sampled_wr wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN LATERAL (
        SELECT CASE WHEN wr.wr_return_amt > 200 THEN 'Very High' ELSE 'Normal' END AS amt_category
    ) la ON TRUE
    LEFT JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN income_band ib ON hd_ret.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    FULL OUTER JOIN cc_dates cc ON cc.cc_date_sk = d.d_date_sk
    FULL OUTER JOIN store_dates s ON s.store_date_sk = d.d_date_sk
)
SELECT DISTINCT
    cc_call_center_id,
    s_store_id,
    d_year,
    r_reason_desc,
    r_reason_id,
    ca_state,
    amt_category,
    rn_state,
    inv_quantity_on_hand,
    ib_lower_bound,
    p_promo_name
FROM joined_all
WHERE d_year = 2000
  AND ca_state = 'CA'
  AND r_reason_id = 'AAAAAAAACAAAAAAA'
ORDER BY rn_state
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
