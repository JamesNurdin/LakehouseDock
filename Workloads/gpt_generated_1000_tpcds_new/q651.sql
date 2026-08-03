WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_current_price,
        i.i_rec_end_date,
        t.t_hour,
        hd_bill.hd_vehicle_count AS bill_vehicle_count,
        hd_ship.hd_vehicle_count AS ship_vehicle_count,
        ws.ws_wholesale_cost
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE hd_bill.hd_vehicle_count >= 0
      AND hd_ship.hd_vehicle_count >= 0
      AND i.i_current_price > 20
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND t.t_hour BETWEEN 9 AND 17
),

item_site_agg AS (
    SELECT
        ws_item_sk,
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sale_cnt
    FROM base
    GROUP BY ws_item_sk, ws_web_site_sk
),

site_agg AS (
    SELECT
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS site_sales,
        AVG(ws_net_profit) AS avg_site_profit
    FROM base
    GROUP BY ws_web_site_sk
),

full_join_agg AS (
    SELECT
        COALESCE(a.ws_item_sk, -1) AS ws_item_sk,
        COALESCE(a.ws_web_site_sk, b.ws_web_site_sk) AS ws_web_site_sk,
        a.total_sales,
        a.total_profit,
        b.site_sales,
        b.avg_site_profit
    FROM item_site_agg a
    FULL OUTER JOIN site_agg b
        ON a.ws_web_site_sk = b.ws_web_site_sk
),

intersect_items AS (
    SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 5
    INTERSECT
    SELECT i_item_sk FROM item WHERE i_current_price < 100
)
SELECT
    f.ws_web_site_sk,
    f.total_sales,
    f.total_profit,
    f.site_sales,
    f.avg_site_profit,
    (
        SELECT COUNT(DISTINCT t2.t_hour)
        FROM time_dim t2
        JOIN web_sales ws2 ON ws2.ws_sold_time_sk = t2.t_time_sk
        WHERE ws2.ws_web_site_sk = f.ws_web_site_sk
    ) AS distinct_sale_hours,
    (
        SELECT COUNT(*)
        FROM intersect_items ii
        JOIN web_sales ws3 ON ws3.ws_item_sk = ii.ws_item_sk
        WHERE ws3.ws_web_site_sk = f.ws_web_site_sk
    ) AS intersect_item_count
FROM full_join_agg f
WHERE f.total_sales > 1000
  AND f.total_profit IS NOT NULL
  AND f.site_sales IS NOT NULL
  AND f.avg_site_profit > 0
ORDER BY f.total_sales DESC
LIMIT 100
