WITH base AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ca.ca_city,
        ca.ca_state,
        ss.ss_net_paid,
        sr.sr_return_amt_inc_tax,
        r.r_reason_desc,
        wr.wr_return_amt_inc_tax
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE ca.ca_state = 'TX'
      AND ca.ca_city = 'Fairview'
      AND sr.sr_return_amt_inc_tax > 500
      AND td.t_hour BETWEEN 9 AND 17
      AND wr.wr_return_amt_inc_tax < 2000
)
SELECT
    ss_store_sk,
    ss_sold_date_sk,
    ca_city,
    ca_state,
    SUM(ss_net_paid) AS total_sales,
    SUM(sr_return_amt_inc_tax) AS total_returns,
    SUM(ss_net_paid) - SUM(sr_return_amt_inc_tax) AS net_profit_est,
    MAX(r_reason_desc) AS sample_reason,
    ROW_NUMBER() OVER (
        PARTITION BY ss_store_sk
        ORDER BY SUM(ss_net_paid) - SUM(sr_return_amt_inc_tax) DESC
    ) AS profit_rank
FROM base
GROUP BY
    ss_store_sk,
    ss_sold_date_sk,
    ca_city,
    ca_state
ORDER BY net_profit_est DESC
LIMIT 100
