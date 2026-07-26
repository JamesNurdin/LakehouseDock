WITH address_sales AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_state,
        ss.ss_sold_date_sk AS date_sk,
        SUM(ss.ss_net_profit) AS daily_profit
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_state, ss.ss_sold_date_sk
),
address_returns AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_state,
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_net_loss) AS daily_loss
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_state, cr.cr_returned_date_sk
),
combined_daily AS (
    SELECT
        s.ca_address_sk,
        s.ca_state,
        s.date_sk,
        s.daily_profit,
        COALESCE(r.daily_loss, 0) AS daily_loss
    FROM address_sales s
    LEFT JOIN address_returns r
        ON s.ca_address_sk = r.ca_address_sk
        AND s.date_sk = r.date_sk
),
cum_metrics AS (
    SELECT
        ca_address_sk,
        ca_state,
        date_sk,
        daily_profit,
        daily_loss,
        SUM(daily_profit) OVER (PARTITION BY ca_address_sk ORDER BY date_sk) AS cum_profit,
        SUM(daily_loss) OVER (PARTITION BY ca_address_sk ORDER BY date_sk) AS cum_loss
    FROM combined_daily
)
SELECT
    ca_address_sk,
    ca_state,
    date_sk,
    daily_profit,
    daily_loss,
    cum_profit,
    cum_loss,
    cum_profit - cum_loss AS net_effect,
    CASE
        WHEN cum_profit - cum_loss > 0 THEN 'Net Positive'
        ELSE 'Net Negative'
    END AS net_status,
    RANK() OVER (PARTITION BY ca_state ORDER BY cum_profit - cum_loss DESC) AS state_address_rank
FROM cum_metrics
WHERE date_sk IS NOT NULL
ORDER BY ca_state, state_address_rank
LIMIT 30
