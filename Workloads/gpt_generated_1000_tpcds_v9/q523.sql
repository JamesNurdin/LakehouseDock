WITH sales_filtered AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        ss_quantity,
        ss_ext_sales_price,
        ss_ext_wholesale_cost,
        ss_net_profit,
        ss_list_price
    FROM store_sales
    WHERE ss_list_price > 50
)
SELECT
    item_sk,
    total_sales_qty,
    total_return_qty,
    total_net_profit,
    profit_status,
    avg_return_amount
FROM (
    SELECT
        r.sr_item_sk AS item_sk,
        SUM(s.ss_quantity) AS total_sales_qty,
        SUM(r.sr_return_quantity) AS total_return_qty,
        SUM(s.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(s.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
        (SELECT AVG(r2.sr_return_amt_inc_tax)
         FROM store_returns r2
         WHERE r2.sr_item_sk = r.sr_item_sk) AS avg_return_amount
    FROM store_returns r
    JOIN sales_filtered s
        ON r.sr_item_sk = s.ss_item_sk
    WHERE r.sr_return_amt_inc_tax > 300
      AND EXISTS (
          SELECT 1
          FROM store_returns r3
          WHERE r3.sr_item_sk = r.sr_item_sk
            AND r3.sr_reversed_charge > 10
      )
    GROUP BY r.sr_item_sk

    UNION ALL

    SELECT
        r.sr_item_sk AS item_sk,
        SUM(s.ss_quantity) AS total_sales_qty,
        SUM(r.sr_return_quantity) AS total_return_qty,
        SUM(s.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(s.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
        (SELECT AVG(r2.sr_return_amt_inc_tax)
         FROM store_returns r2
         WHERE r2.sr_item_sk = r.sr_item_sk) AS avg_return_amount
    FROM store_returns r
    JOIN store_sales s
        ON r.sr_ticket_number = s.ss_ticket_number
    WHERE s.ss_ext_sales_price > 1000
      AND EXISTS (
          SELECT 1
          FROM store_returns r3
          WHERE r3.sr_item_sk = r.sr_item_sk
            AND r3.sr_reversed_charge > 10
      )
    GROUP BY r.sr_item_sk
) combined
ORDER BY total_net_profit DESC
LIMIT 100
