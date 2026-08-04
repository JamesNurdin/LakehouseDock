WITH online_purchasers AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE i.i_category = 'Electronics'
      AND ws.ws_net_paid > 1000
),
online_returners AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE i.i_category = 'Electronics'
      AND wr.wr_return_amt > 0
)
SELECT c_customer_id
FROM (
    SELECT c_customer_id FROM online_purchasers
    EXCEPT
    SELECT c_customer_id FROM online_returners
) AS diff
ORDER BY c_customer_id
LIMIT 100
