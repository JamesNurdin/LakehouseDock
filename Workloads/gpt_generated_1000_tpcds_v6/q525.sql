/*
Goal: Analyze return and web sales performance for female married customers with at least two employed dependents, focusing on medium‑size returns and higher‑value web sales. The query joins store_returns, customer_demographics, and web_sales, applies several selective filters, aggregates key metrics, categorizes customers by credit rating, adds a running total window function, orders the results by total return amount, and limits output to 100 rows.
*/
WITH agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE WHEN cd.cd_credit_rating = 'A' THEN 'High' ELSE 'Other' END AS credit_group,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        MIN(sr.sr_return_ship_cost) AS min_ship_cost,
        MAX(ws.ws_net_profit) AS max_net_profit
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_employed_count >= 2
      AND sr.sr_return_amt BETWEEN 50 AND 500
      AND ws.ws_net_paid > 200
    GROUP BY
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE WHEN cd.cd_credit_rating = 'A' THEN 'High' ELSE 'Other' END
)
SELECT
    agg.cd_demo_sk,
    agg.cd_gender,
    agg.cd_marital_status,
    agg.credit_group,
    agg.orders_cnt,
    agg.total_return_amt,
    agg.avg_net_paid,
    agg.min_ship_cost,
    agg.max_net_profit,
    SUM(agg.total_return_amt) OVER (
        PARTITION BY agg.credit_group
        ORDER BY agg.total_return_amt DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_return
FROM agg
ORDER BY agg.total_return_amt DESC
LIMIT 100
