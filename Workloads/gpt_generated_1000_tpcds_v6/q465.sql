WITH ws_filtered AS (
        SELECT
            ws_order_number,
            ws_bill_customer_sk,
            ws_item_sk,
            ws_ext_sales_price,
            ws_net_profit,
            ws_sold_date_sk
        FROM web_sales
        WHERE ws_ext_sales_price > 100
          AND ws_sold_date_sk BETWEEN 2450000 AND 2459999
    ),
    sr_filtered AS (
        SELECT
            sr_customer_sk,
            sr_item_sk,
            sr_return_amt,
            sr_reason_sk,
            sr_return_quantity
        FROM store_returns
        WHERE sr_return_quantity > 5
    )
SELECT
    c.c_customer_id,
    i.i_item_id,
    i.i_current_price,
    r.r_reason_desc,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    sr.sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM ws_filtered ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN sr_filtered sr
    ON sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE c.c_birth_month IN (3, 7, 12)
  AND i.i_current_price BETWEEN 20 AND 200
  AND r.r_reason_desc LIKE '%size%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > 50
      )
ORDER BY profit_rank
LIMIT 100
