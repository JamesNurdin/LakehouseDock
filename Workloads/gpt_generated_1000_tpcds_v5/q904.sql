WITH ws_filtered AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_coupon_amt,
        ws.ws_ship_cdemo_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_sales_price > 50.00                     -- filter on high sales price
      AND ws.ws_coupon_amt > 0.00                       -- only rows with a coupon applied
      AND ws.ws_ship_cdemo_sk IN (964622, 634525, 223802, 425900) -- specific demographic codes
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999 -- surrogate date key range
)
SELECT
    i.i_category,
    i.i_class,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    MIN(sr.sr_return_tax) AS min_return_tax,
    MAX(ws.ws_coupon_amt) AS max_coupon_amt
FROM ws_filtered ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_tax > 10.00               -- return tax above threshold
          AND sr2.sr_return_ship_cost < 500.00        -- reasonable shipping cost
          AND sr2.sr_customer_sk IN (9806179, 7948740, 507642) -- specific customers
    )
  AND sr.sr_return_amt > 20.00                         -- filter on return amount
GROUP BY i.i_category, i.i_class
ORDER BY total_sales DESC
LIMIT 100
