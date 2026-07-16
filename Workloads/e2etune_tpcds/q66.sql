WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_ext_sales_price) AS total_sales_price,
        SUM(ss_net_profit) AS total_sales_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450300
    GROUP BY ss_item_sk, ss_ticket_number
)
SELECT
    sr.sr_store_sk AS store_sk,
    sr.sr_returned_date_sk AS return_date_sk,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    SUM(sr.sr_net_loss) AS total_return_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    SUM(COALESCE(sa.total_sales_price, 0)) AS related_sales_price,
    SUM(COALESCE(sa.total_sales_profit, 0)) AS related_sales_profit,
    RANK() OVER (ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank
FROM store_returns sr
LEFT JOIN sales_agg sa
    ON sr.sr_item_sk = sa.ss_item_sk
    AND sr.sr_ticket_number = sa.ss_ticket_number
WHERE sr.sr_return_amt > 1000
    AND sr.sr_hdemo_sk IN (6560, 6178, 896)
GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
HAVING SUM(sr.sr_return_amt_inc_tax) > 5000
ORDER BY total_return_net_loss DESC
LIMIT 30
