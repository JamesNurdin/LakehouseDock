WITH joined_data AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_return_amt AS sr_return_amt,
        sr.sr_net_loss AS sr_net_loss
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    store_sk,
    item_sk,
    SUM(ss_quantity) AS total_sales_quantity,
    SUM(ss_net_paid) AS total_sales_net_paid,
    SUM(ss_net_profit) AS total_sales_net_profit,
    SUM(sr_return_quantity) AS total_return_quantity,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_net_loss) AS total_return_net_loss,
    (SUM(ss_net_profit) - SUM(sr_net_loss)) AS net_profit_after_returns,
    CASE 
        WHEN SUM(ss_quantity) > 0 
        THEN SUM(sr_return_quantity) / SUM(ss_quantity) 
        ELSE 0 
    END AS return_quantity_ratio
FROM joined_data
GROUP BY store_sk, item_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
