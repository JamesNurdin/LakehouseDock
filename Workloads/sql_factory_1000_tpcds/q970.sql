WITH all_returns AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        cr_returned_date_sk AS return_date_sk,
        cr_net_loss AS net_loss,
        'catalog' AS source
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_refunded_customer_sk,
        wr_returned_date_sk,
        wr_net_loss,
        'web' AS source
    FROM web_returns
),
 daily_customer_loss AS (
    SELECT
        customer_sk,
        return_date_sk,
        SUM(net_loss) AS daily_net_loss,
        SUM(CASE WHEN source = 'catalog' THEN net_loss ELSE 0 END) AS catalog_net_loss,
        SUM(CASE WHEN source = 'web' THEN net_loss ELSE 0 END) AS web_net_loss
    FROM all_returns
    GROUP BY customer_sk, return_date_sk
),
 running_totals AS (
    SELECT
        dcl.customer_sk,
        dcl.return_date_sk,
        dcl.daily_net_loss,
        dcl.catalog_net_loss,
        dcl.web_net_loss,
        SUM(dcl.daily_net_loss) OVER (PARTITION BY dcl.customer_sk ORDER BY dcl.return_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
        LAG(dcl.daily_net_loss) OVER (PARTITION BY dcl.customer_sk ORDER BY dcl.return_date_sk) AS prev_daily_net_loss
    FROM daily_customer_loss dcl
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rt.return_date_sk,
    rt.daily_net_loss,
    rt.cumulative_net_loss,
    CASE
        WHEN rt.prev_daily_net_loss IS NULL THEN 'N/A'
        WHEN rt.daily_net_loss > rt.prev_daily_net_loss THEN 'Increasing'
        WHEN rt.daily_net_loss < rt.prev_daily_net_loss THEN 'Decreasing'
        ELSE 'Stable'
    END AS trend_indicator
FROM running_totals rt
JOIN customer c
    ON rt.customer_sk = c.c_customer_sk
WHERE rt.return_date_sk = (
    SELECT MAX(return_date_sk) FROM running_totals rt2 WHERE rt2.customer_sk = rt.customer_sk
)
ORDER BY rt.cumulative_net_loss DESC
LIMIT 20
