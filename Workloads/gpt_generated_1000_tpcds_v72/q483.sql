WITH joined AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_net_loss,
        sr.sr_return_amt,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        td.t_hour,
        td.t_minute
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE
        sr.sr_store_credit > 100.00
        AND sr.sr_reversed_charge < 500.00
        AND sr.sr_return_tax BETWEEN 0.5 AND 80.0
        AND ws.ws_net_paid_inc_tax >= 1000.00
        AND ws.ws_list_price <= 200.00
        AND td.t_hour IN (5, 7, 11)
)
SELECT
    j.sr_store_sk,
    j.t_hour,
    COUNT(DISTINCT j.sr_customer_sk) AS distinct_customers,
    SUM(j.sr_net_loss) AS total_net_loss,
    AVG(j.ws_net_paid_inc_tax) AS avg_paid_inc_tax,
    MAX(j.ws_net_profit) AS max_profit,
    MIN(j.ws_net_profit) AS min_profit,
    SUM(j.sr_return_amt) AS total_return_amount
FROM joined j
GROUP BY j.sr_store_sk, j.t_hour
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
