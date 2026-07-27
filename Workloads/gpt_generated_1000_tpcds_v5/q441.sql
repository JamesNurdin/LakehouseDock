WITH base AS (
    SELECT
        wr.wr_returning_customer_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        r.r_reason_desc,
        CASE 
            WHEN ib.ib_upper_bound >= 180000 THEN 'High Income'
            WHEN ib.ib_upper_bound >= 90000  THEN 'Mid Income'
            ELSE 'Low Income'
        END AS income_category
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND ca.ca_state IN ('CA', 'NY', 'TX')
      AND ib.ib_upper_bound >= 90000
      AND r.r_reason_desc LIKE '%damaged%'
      AND c.c_preferred_cust_flag = 'Y'
),
agg AS (
    SELECT
        ca_state,
        income_category,
        r_reason_desc,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        SUM(wr_return_amt) AS total_return_amount,
        AVG(wr_return_tax) AS avg_return_tax,
        MIN(wr_net_loss) AS min_net_loss,
        MAX(wr_net_loss) AS max_net_loss
    FROM base
    GROUP BY ca_state, income_category, r_reason_desc
)
SELECT
    ca_state,
    income_category,
    r_reason_desc,
    distinct_customers,
    total_return_amount,
    avg_return_tax,
    min_net_loss,
    max_net_loss,
    SUM(total_return_amount) OVER (
        PARTITION BY ca_state
        ORDER BY income_category
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_state
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
