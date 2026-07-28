WITH joined AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_refunded_cash,
        sr.sr_net_loss,
        ss.ss_store_sk AS ss_store_sk,
        ss.ss_item_sk AS ss_item_sk,
        ss.ss_ext_tax,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_sales_price,
        ss.ss_wholesale_cost
    FROM store_returns sr
    JOIN store_sales ss
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE ss.ss_ext_tax > 20
      AND sr.sr_refunded_cash < 500
      AND ss.ss_wholesale_cost < 50
),
agg AS (
    SELECT
        j.ss_store_sk,
        j.ss_item_sk,
        SUM(j.ss_ext_sales_price) AS total_sales,
        SUM(j.sr_return_amt_inc_tax) AS total_returns,
        SUM(j.sr_net_loss) AS total_net_loss,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(j.sr_net_loss) > 0 THEN 'LOSS' ELSE 'PROFIT' END AS net_status
    FROM joined j
    GROUP BY GROUPING SETS (
        (j.ss_store_sk, j.ss_item_sk),
        (j.ss_store_sk)
    )
    HAVING SUM(j.ss_ext_sales_price) > 1000
)
SELECT
    ss_store_sk,
    ss_item_sk,
    total_sales,
    total_returns,
    total_net_loss,
    txn_count,
    net_status,
    RANK() OVER (PARTITION BY ss_store_sk ORDER BY total_net_loss DESC) AS loss_rank_by_item,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS overall_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
