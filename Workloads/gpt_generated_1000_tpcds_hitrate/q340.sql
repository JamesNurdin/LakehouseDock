WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM tpcds.web_sales ws
    JOIN tpcds.web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
       AND ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_web_site_sk IN (48, 19, 45, 50, 42)               -- predicate 1
      AND ws.ws_bill_cdemo_sk = 436090                           -- predicate 2
      AND ws.ws_net_paid_inc_tax > 1000.00                       -- predicate 3
      AND wr.wr_return_amt BETWEEN 10.00 AND 500.00               -- predicate 4
      AND wr.wr_return_quantity >= 1                             -- predicate 5
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
              AND wr2.wr_return_quantity > 1
        )                                                       -- predicate 6 (subquery)
),
aggregated AS (
    SELECT
        ws_order_number,
        ws_web_site_sk,
        ws_bill_cdemo_sk,
        SUM(ws_net_paid_inc_tax)   AS total_paid,
        AVG(wr_return_amt)         AS avg_return_amt,
        COUNT(*)                   AS txn_cnt
    FROM sales_returns
    GROUP BY ws_order_number, ws_web_site_sk, ws_bill_cdemo_sk
    HAVING SUM(ws_net_paid_inc_tax) > 2000.00
),
exclude_set AS (
    SELECT ws_order_number, ws_web_site_sk, ws_bill_cdemo_sk
    FROM aggregated
    WHERE avg_return_amt < 50.00
)
-- First result set (with pagination)
(
    SELECT
        a.ws_order_number,
        a.ws_web_site_sk,
        a.ws_bill_cdemo_sk,
        a.total_paid,
        a.avg_return_amt,
        a.txn_cnt
    FROM aggregated a
    WHERE (a.ws_order_number, a.ws_web_site_sk, a.ws_bill_cdemo_sk) NOT IN (
        SELECT ws_order_number, ws_web_site_sk, ws_bill_cdemo_sk FROM exclude_set
    )
    ORDER BY a.total_paid DESC
    OFFSET 0 LIMIT 100
)
EXCEPT
-- Second result set to be subtracted (also paginated)
(
    SELECT
        ws_order_number,
        ws_web_site_sk,
        ws_bill_cdemo_sk,
        total_paid,
        avg_return_amt,
        txn_cnt
    FROM aggregated
    WHERE txn_cnt < 5
    ORDER BY total_paid ASC
    OFFSET 0 LIMIT 100
)
