/* goal: Identify high‑value customers (based on purchase estimate) who have generated sales either in stores or on the web, and who also have at least one catalog return record. */
WITH
    store_filtered AS (
        SELECT
            ss.ss_cdemo_sk AS cdemo_sk,
            ss.ss_net_paid AS net_paid
        FROM store_sales ss
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_purchase_estimate > 8000
          AND ss.ss_net_paid > 1000
    ),
    web_filtered AS (
        SELECT
            ws.ws_bill_cdemo_sk AS cdemo_sk,
            ws.ws_net_paid_inc_ship AS net_paid
        FROM web_sales ws
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_purchase_estimate > 8000
          AND ws.ws_net_paid_inc_ship > 1000
    ),
    combined_sales AS (
        SELECT cdemo_sk, SUM(net_paid) AS total_sales
        FROM (
            SELECT cdemo_sk, net_paid FROM store_filtered
            UNION ALL
            SELECT cdemo_sk, net_paid FROM web_filtered
        ) u
        GROUP BY cdemo_sk
    )
SELECT DISTINCT
    cs.cdemo_sk,
    cs.total_sales
FROM combined_sales cs
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE (cr.cr_refunded_cdemo_sk = cs.cdemo_sk OR cr.cr_returning_cdemo_sk = cs.cdemo_sk)
      AND cr.cr_return_amount > 0
)
ORDER BY cs.total_sales DESC
LIMIT 100
