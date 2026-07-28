WITH returns_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss
    FROM web_returns
    WHERE wr_return_tax > 50
    GROUP BY wr_order_number
)
SELECT
    w.w_warehouse_name,
    hd.hd_buy_potential,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(r.total_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(r.total_net_loss, 0)) AS total_return_loss
FROM web_sales ws
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN returns_agg r
  ON ws.ws_order_number = r.wr_order_number
WHERE w.w_warehouse_sq_ft > 600000
  AND w.w_county = 'Bronx County'
  AND hd.hd_buy_potential = '>10000'
  AND ws.ws_quantity >= 2
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_amt_inc_tax > 1000
    )
GROUP BY w.w_warehouse_name, hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
