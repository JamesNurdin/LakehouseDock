WITH cr_agg AS (
    SELECT
        cr_returned_date_sk,
        SUM(cr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS total_returns
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amt_inc_tax IS NOT NULL
      AND cr_fee >= 0
      AND cr_return_ship_cost >= 0
      AND cr_net_loss >= 0
    GROUP BY cr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    ca.total_returns,
    ca.total_return_inc_tax,
    ws.web_site_id,
    ws.web_company_id,
    ws.web_state,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ca.total_return_inc_tax DESC) AS yearly_return_rank,
    CASE
        WHEN ca.total_return_inc_tax > 5000 THEN 'High'
        WHEN ca.total_return_inc_tax > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM cr_agg ca
FULL OUTER JOIN date_dim d
    ON ca.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_current_quarter = 'Y'
  AND d.d_same_day_lq > 2414930
  AND ws.web_company_id IN (1, 3, 5)
  AND ws.web_state = 'CA'
ORDER BY yearly_return_rank, d.d_date
LIMIT 100
