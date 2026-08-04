WITH base AS (
    SELECT
        w.w_state,
        hd.hd_buy_potential,
        ss.ss_ticket_number,
        ws.ws_order_number,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        ss.ss_quantity,
        ws.ws_quantity,
        ss.ss_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_net_paid_inc_tax
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_vehicle_count >= 1
)
SELECT
    w_state,
    hd_buy_potential,
    COUNT(DISTINCT ss_ticket_number) AS store_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders,
    SUM(ss_ext_sales_price) AS store_sales,
    SUM(ws_ext_sales_price) AS web_sales,
    AVG(ss_quantity) AS avg_store_qty,
    AVG(ws_quantity) AS avg_web_qty
FROM base
WHERE ss_sold_date_sk BETWEEN 2451230 AND 2451531
  AND ws_ship_date_sk = 2451411
  AND w_state = 'NY'
GROUP BY w_state, hd_buy_potential

UNION

SELECT
    w_state,
    hd_buy_potential,
    COUNT(DISTINCT ss_ticket_number) AS store_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders,
    SUM(ss_ext_sales_price) AS store_sales,
    SUM(ws_ext_sales_price) AS web_sales,
    AVG(ss_quantity) AS avg_store_qty,
    AVG(ws_quantity) AS avg_web_qty
FROM (
    SELECT
        w.w_state,
        hd.hd_buy_potential,
        ss.ss_ticket_number,
        ws.ws_order_number,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        ss.ss_quantity,
        ws.ws_quantity,
        ss.ss_sold_date_sk,
        ws.ws_net_paid_inc_tax
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'AL'
      AND hd.hd_vehicle_count >= 1
) t
WHERE t.ss_sold_date_sk BETWEEN 2451522 AND 2451858
  AND t.ws_net_paid_inc_tax > 1000
GROUP BY w_state, hd_buy_potential

ORDER BY store_sales DESC
LIMIT 100
