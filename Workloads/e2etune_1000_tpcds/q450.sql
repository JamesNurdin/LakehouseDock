SELECT
    ca.ca_state AS state,
    ib.ib_income_band_sk AS income_band_id,
    ib.ib_lower_bound AS lower_bound,
    ib.ib_upper_bound AS upper_bound,
    COUNT(*) AS num_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank_in_state
FROM web_returns wr
JOIN customer_address ca
    ON wr.wr_returning_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
JOIN income_band ib
    ON wr.wr_net_loss BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE ca.ca_country = 'United States'
  AND ca.ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
  AND cd.cd_gender = 'M'
  AND wr.wr_returned_date_sk >= 2450000
GROUP BY ca.ca_state, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(wr.wr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 50
