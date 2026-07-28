WITH catalog_agg AS (
    SELECT
        cc.cc_company AS company_id,
        cc.cc_state AS state,
        t.t_hour AS hour_of_day,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(cr.cr_return_quantity) AS avg_qty
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cc.cc_company IN (1, 2, 5)
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY ROLLUP(cc.cc_company, cc.cc_state, t.t_hour)
),
web_agg AS (
    SELECT
        CAST(NULL AS integer) AS company_id,
        ca.ca_state AS state,
        t.t_hour AS hour_of_day,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        AVG(wr.wr_return_quantity) AS avg_qty
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY CUBE(ca.ca_state, t.t_hour)
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT DISTINCT
    company_id,
    state,
    hour_of_day,
    total_return_amount,
    distinct_orders,
    avg_qty,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_return_amount DESC) AS state_rank
FROM combined
ORDER BY state_rank, total_return_amount DESC
LIMIT 100
