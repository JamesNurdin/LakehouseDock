WITH ws_agg AS (
  SELECT
    w.w_warehouse_name,
    d.d_year,
    d.d_moy,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    AND regexp_like(w.w_warehouse_name, '^WH[0-9]+')
    AND hd.hd_buy_potential LIKE '%1000%'
    AND EXISTS (
      SELECT 1 FROM inventory inv
      WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_quantity_on_hand > 500
    )
  GROUP BY w.w_warehouse_name, d.d_year, d.d_moy
)
SELECT
  a.w_warehouse_name,
  a.d_year,
  a.d_moy,
  a.total_profit,
  a.order_cnt,
  regexp_extract(a.w_warehouse_name, '[0-9]+') AS warehouse_id_num,
  SUM(a.total_profit) OVER (
    PARTITION BY a.w_warehouse_name
    ORDER BY a.d_year, a.d_moy
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_profit,
  LAG(a.total_profit) OVER (
    PARTITION BY a.w_warehouse_name
    ORDER BY a.d_year, a.d_moy
  ) AS prior_month_profit
FROM ws_agg a
ORDER BY a.total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
