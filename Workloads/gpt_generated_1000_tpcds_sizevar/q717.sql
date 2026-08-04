WITH
    -- Aggregate sales per call center and billing customer
    agg_sales AS (
        SELECT
            cs.cs_call_center_sk,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            SUM(cs.cs_net_profit)   AS total_profit,
            COUNT(*)                AS sales_cnt
        FROM catalog_sales cs
        GROUP BY
            cs.cs_call_center_sk,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk
    ),
    -- 10 % Bernoulli sample of catalog_returns
    sample_returns AS (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    -- Filtered call centers (example states)
    call_center_filtered AS (
        SELECT cc.*
        FROM call_center cc
        WHERE cc.cc_state IN ('CA', 'TX')
    ),
    -- Call‑center keys that appear both in the filtered list and have positive profit
    intersect_cc AS (
        SELECT cc.cc_call_center_sk
        FROM call_center_filtered cc
        INTERSECT
        SELECT asales.cs_call_center_sk
        FROM agg_sales asales
        WHERE asales.total_profit > 0
    ),
    -- Two separate aliases of the date dimension (open / closed dates)
    date_open AS (
        SELECT d.*
        FROM date_dim d
        WHERE d.d_year = 2001
    ),
    date_closed AS (
        SELECT d.*
        FROM date_dim d
        WHERE d.d_year = 2001
    )
SELECT
    cc.cc_call_center_id,
    d_open.d_date               AS open_date,
    d_closed.d_date             AS closed_date,
    agg.total_profit,
    agg.sales_cnt,
    CASE WHEN agg.total_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_bucket,
    cust.c_first_name,
    cust.c_last_name,
    cd.cd_credit_rating,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wr.wr_net_loss,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = d_open.d_date_sk
          AND cr2.cr_call_center_sk   = cc.cc_call_center_sk
    ) AS total_return_amount
FROM intersect_cc ic
JOIN call_center cc
    ON cc.cc_call_center_sk = ic.cc_call_center_sk
LEFT JOIN agg_sales agg
    ON agg.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN date_open d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
LEFT JOIN date_closed d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
LEFT JOIN customer cust
    ON agg.cs_bill_customer_sk = cust.c_customer_sk
LEFT JOIN customer_demographics cd
    ON agg.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON agg.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN time_dim t
    ON agg.cs_sold_time_sk = t.t_time_sk
-- Raw catalog_sales row to enable the FULL OUTER JOIN on order number
LEFT JOIN catalog_sales cs_raw
    ON cs_raw.cs_call_center_sk = cc.cc_call_center_sk
FULL OUTER JOIN catalog_returns cr_full
    ON cr_full.cr_order_number = cs_raw.cs_order_number
LEFT JOIN sample_returns sr
    ON cr_full.cr_returned_date_sk = sr.cr_returned_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_closed.d_date_sk
WHERE cc.cc_company_name IS NOT NULL
ORDER BY agg.total_profit DESC
LIMIT 100
