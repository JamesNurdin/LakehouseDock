/* goal: Identify the relationship between store return loss and web sales performance for male, college‑educated customers in the current year, while excluding customers who had very large web purchases */
WITH ws_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_order_number,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        ws.ws_net_paid
    FROM web_sales ws
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001                -- selective year filter
      AND d_ws.d_month_seq BETWEEN 1200 AND 1202   -- restrict to a few months
      AND ws.ws_net_paid_inc_tax > 1000.00        -- focus on higher‑value sales
)
SELECT
    d_ret.d_year,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT sr.sr_ticket_number)           AS return_transactions,
    SUM(sr.sr_net_loss)                           AS total_return_loss,
    AVG(ws.ws_net_paid_inc_tax)                   AS avg_web_sales_inc_tax,
    MIN(ws.ws_net_paid)                           AS min_web_net_paid,
    MAX(sr.sr_return_amt)                        AS max_return_amount
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN ws_filtered ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE d_ret.d_current_year = 'Y'                 -- current‑year flag filter
  AND cd.cd_gender = 'M'                         -- male customers only
  AND cd.cd_education_status = 'College'        -- college‑educated only
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN date_dim d2
            ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE ws2.ws_bill_customer_sk = sr.sr_customer_sk
          AND d2.d_year = 2001
          AND ws2.ws_net_paid_inc_tax > 5000.00   -- exclude customers with very large web purchases
    )
GROUP BY d_ret.d_year, cd.cd_gender, cd.cd_marital_status
ORDER BY total_return_loss DESC
LIMIT 100
