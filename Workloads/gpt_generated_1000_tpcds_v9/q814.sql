WITH sales_filtered AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_ship_mode_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk = 2
      AND ws.ws_net_paid_inc_ship > 2000
),
joined AS (
    SELECT
        w.w_city,
        hd.hd_buy_potential,
        s.ws_ext_sales_price,
        s.ws_net_paid,
        s.ws_ship_mode_sk,
        s.ws_order_number
    FROM sales_filtered s
    JOIN household_demographics hd
      ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
      ON s.ws_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_dep_count IN (7, 8, 9)
      AND hd.hd_vehicle_count > 0
      AND w.w_city = 'Fairview'
),
agg AS (
    SELECT
        w_city,
        hd_buy_potential,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_net_paid) AS avg_net_paid,
        COUNT(*) AS order_count,
        MIN(ws_ship_mode_sk) AS min_ship_mode,
        MAX(ws_ship_mode_sk) AS max_ship_mode
    FROM joined
    GROUP BY GROUPING SETS (
        (w_city, hd_buy_potential),
        (w_city),
        (hd_buy_potential),
        ()
    )
)
SELECT
    w_city,
    hd_buy_potential,
    total_sales,
    total_net_paid,
    avg_net_paid,
    order_count,
    min_ship_mode,
    max_ship_mode,
    ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_sales DESC) AS sales_rank_by_city
FROM agg
ORDER BY w_city ASC NULLS LAST,
         hd_buy_potential ASC NULLS LAST,
         total_sales DESC
LIMIT 100
