WITH store_losses AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_net_loss) AS total_store_loss,
           d.d_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY sr.sr_customer_sk, d.d_year
),
web_losses AS (
    SELECT wr.wr_returning_customer_sk AS customer_sk,
           SUM(wr.wr_net_loss) AS total_web_loss,
           d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY wr.wr_returning_customer_sk, d.d_year
),
combined_losses AS (
    SELECT customer_sk,
           total_store_loss AS total_loss,
           'store' AS source
    FROM store_losses
    UNION ALL
    SELECT customer_sk,
           total_web_loss AS total_loss,
           'web' AS source
    FROM web_losses
)
SELECT cl.customer_sk,
       c.c_first_name,
       c.c_last_name,
       cl.total_loss,
       cl.source
FROM combined_losses cl
JOIN customer c ON cl.customer_sk = c.c_customer_sk
WHERE cl.total_loss > (
    SELECT AVG(inner_cl.total_loss)
    FROM combined_losses inner_cl
)
ORDER BY cl.total_loss DESC
LIMIT 100
