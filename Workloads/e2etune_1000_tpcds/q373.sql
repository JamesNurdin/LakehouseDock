WITH store_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_fee) AS total_fee,
        SUM(ss.ss_net_paid) AS total_sales_net_paid,
        SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE sr.sr_returned_date_sk BETWEEN 2451653 AND 2452688
      AND sr.sr_fee > 10
      AND sr.sr_store_sk IN (176, 466)
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    sr_store_sk,
    sr_reason_sk,
    total_return_amount,
    total_refunded_cash,
    total_fee,
    total_sales_net_paid,
    total_sales_net_profit,
    ROUND((total_return_amount / NULLIF(total_sales_net_paid, 0)) * 100, 2) AS return_to_sales_pct,
    ROUND((total_fee / NULLIF(total_sales_net_paid, 0)) * 100, 2) AS fee_to_sales_pct,
    RANK() OVER (PARTITION BY sr_store_sk ORDER BY total_return_amount DESC) AS reason_rank
FROM store_agg
ORDER BY total_return_amount DESC
LIMIT 20
