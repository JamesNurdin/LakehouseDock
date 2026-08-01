WITH returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    TABLESAMPLE BERNOULLI (10)
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_fee > 5
      AND wr.wr_returning_hdemo_sk IN (
            SELECT hd_demo_sk
            FROM household_demographics
            WHERE hd_income_band_sk = 4
        )
    GROUP BY wr.wr_order_number, wr.wr_item_sk
), item_distinct AS (
    SELECT DISTINCT i_item_sk
    FROM item
    WHERE i_current_price > 50
)
SELECT
    i.i_category,
    i.i_brand,
    hd_bill.hd_income_band_sk,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(COALESCE(r.total_return_loss, 0)) AS total_return_loss,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
TABLESAMPLE BERNOULLI (5)
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN item_distinct id ON i.i_item_sk = id.i_item_sk
LEFT JOIN returns_agg r
    ON ws.ws_order_number = r.wr_order_number
   AND ws.ws_item_sk = r.wr_item_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item) * 0.5
  AND i.i_brand_id IN (1, 2, 3)
  AND ws.ws_quantity >= 2
  AND ws.ws_net_profit > 0
  AND hd_bill.hd_dep_count >= 2
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 0
    )
GROUP BY CUBE (i.i_category, i.i_brand, hd_bill.hd_income_band_sk)
ORDER BY total_sales DESC
LIMIT 100
