WITH store_ret AS (
    SELECT d.d_year AS year,
           hd.hd_income_band_sk AS income_band,
           ca.ca_state AS state,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_ret AS (
    SELECT d.d_year AS year,
           hd.hd_income_band_sk AS income_band,
           ca.ca_state AS state,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_ret AS (
    SELECT d.d_year AS year,
           hd.hd_income_band_sk AS income_band,
           ca.ca_state AS state,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
all_ret AS (
    SELECT year, income_band, state, net_loss FROM store_ret
    UNION ALL
    SELECT year, income_band, state, net_loss FROM catalog_ret
    UNION ALL
    SELECT year, income_band, state, net_loss FROM web_ret
)
SELECT year,
       income_band,
       state,
       SUM(net_loss) AS total_net_loss
FROM all_ret
GROUP BY year, income_band, state
ORDER BY total_net_loss DESC
LIMIT 20
