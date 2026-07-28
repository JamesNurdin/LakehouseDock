WITH filtered_sales AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_net_profit,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    WHERE ws.ws_net_profit > 1000
      AND ws.ws_ext_discount_amt < 500
      AND ws.ws_quantity >= 1
      AND EXISTS (
          SELECT 1
          FROM warehouse w2
          WHERE w2.w_warehouse_sk = ws.ws_warehouse_sk
            AND w2.w_zip = '44593'
      )
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax,
    ROW_NUMBER() OVER (ORDER BY SUM(fs.ws_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
JOIN warehouse w
    ON fs.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
  AND w.w_zip LIKE '44%'
GROUP BY w.w_warehouse_id, w.w_city, w.w_state
HAVING SUM(fs.ws_net_profit) > 5000
ORDER BY profit_rank
