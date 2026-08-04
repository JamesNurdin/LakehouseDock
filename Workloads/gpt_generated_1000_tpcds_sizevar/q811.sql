WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_net_paid) AS sum_net_paid,
        SUM(ws_ext_tax) AS sum_ext_tax,
        AVG(ws_coupon_amt) AS avg_coupon_amt,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450130
      AND ws_ext_wholesale_cost > 1000
      AND ws_ext_tax < 100
      AND ws_coupon_amt <> 0
      AND ws_list_price BETWEEN 10 AND 10000
      AND ws_sales_price IS NOT NULL
    GROUP BY ws_item_sk, ws_order_number
),
wr_filtered AS (
    SELECT
        wr_item_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        wr_return_ship_cost,
        wr_account_credit,
        wr_reversed_charge,
        wr_net_loss
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 0
      AND wr_return_ship_cost BETWEEN 5 AND 5000
      AND wr_account_credit < 1000
      AND wr_reversed_charge <> 0
      AND wr_net_loss > -10000
      AND wr_item_sk IN (
          SELECT ws_item_sk FROM web_sales WHERE ws_ext_wholesale_cost > 3000
      )
)
SELECT
    ws.ws_item_sk,
    ws.ws_order_number,
    ws.sum_net_paid,
    ws.sum_ext_tax,
    ws.avg_coupon_amt,
    ws.sales_cnt,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    CASE
        WHEN ws.sum_net_paid = 0 THEN 0
        ELSE (ws.sum_net_paid - ws.sum_ext_tax) / ws.sum_net_paid
    END AS profit_ratio,
    lt.total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.sum_net_paid DESC) AS rn
FROM ws_agg ws
JOIN wr_filtered wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
CROSS JOIN LATERAL (
    SELECT SUM(wr2.wr_net_loss) AS total_return_loss
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = ws.ws_item_sk
      AND wr2.wr_order_number = ws.ws_order_number
) lt
WHERE CASE
        WHEN ws.sum_net_paid > 5000 THEN 1
        ELSE 0
      END = 1
  AND EXISTS (
        SELECT 1 FROM web_sales ws3
        WHERE ws3.ws_item_sk = ws.ws_item_sk
          AND ws3.ws_ext_tax > 20
    )
ORDER BY profit_ratio DESC, ws.sum_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
