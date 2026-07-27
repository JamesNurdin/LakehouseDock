WITH agg_a AS (
    SELECT
        hd.hd_buy_potential,
        w.w_city,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_wr_net_loss,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM tpcds.household_demographics hd
    JOIN tpcds.store_returns sr
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE hd.hd_buy_potential = '>10000'
      AND w.w_city = 'Seattle'
      AND ws.ws_quantity > 5
      AND sr.sr_return_quantity > 1
      AND wr.wr_fee > 10
    GROUP BY hd.hd_buy_potential, w.w_city
),
agg_b AS (
    SELECT
        hd.hd_buy_potential,
        w.w_city,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_wr_net_loss,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM tpcds.household_demographics hd
    JOIN tpcds.store_returns sr
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE hd.hd_buy_potential = '0-500'
      AND w.w_city = 'Boston'
      AND ws.ws_quantity <= 3
      AND sr.sr_return_quantity = 0
      AND wr.wr_fee < 5
    GROUP BY hd.hd_buy_potential, w.w_city
)
SELECT * FROM agg_a
UNION ALL
SELECT * FROM agg_b
ORDER BY total_net_paid DESC
LIMIT 100
