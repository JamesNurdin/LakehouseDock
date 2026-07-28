WITH filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity,
        d.d_year,
        d.d_date,
        s.s_store_sk,
        s.s_state,
        s.s_company_name,
        s.s_number_employees,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_store_credit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    WHERE cs.cs_bill_addr_sk IN (580361, 2121279)
      AND cs.cs_net_paid_inc_tax > 1000
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND d.d_year = 2001
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND s.s_number_employees >= 200
      AND sr.sr_return_tax < 10
)
SELECT
    d_year,
    s_state,
    s_company_name,
    COUNT(*) AS transaction_count,
    SUM(cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(sr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
    MIN(cs_quantity) AS min_quantity,
    MAX(cs_quantity) AS max_quantity,
    SUM(sr_store_credit) AS total_store_credit
FROM filtered
GROUP BY d_year, s_state, s_company_name
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
