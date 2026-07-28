WITH billed_sales AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        ws.ws_web_site_sk AS site_key,
        ws.ws_ship_date_sk AS ship_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE w.w_county = 'Bronx County'
      AND s.web_name = 'OnlineStoreA'
      AND ws.ws_ship_date_sk BETWEEN 2452300 AND 2452400
    GROUP BY w.w_warehouse_id, ws.ws_web_site_sk, ws.ws_ship_date_sk
    HAVING SUM(ws.ws_net_profit) > 5000
),
shipped_sales AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        ws.ws_web_site_sk AS site_key,
        ws.ws_ship_date_sk AS ship_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    JOIN tpcds.customer c
        ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE w.w_county = 'Ziebach County'
      AND s.web_class = 'ClassA'
      AND ws.ws_ship_date_sk BETWEEN 2451900 AND 2452000
    GROUP BY w.w_warehouse_id, ws.ws_web_site_sk, ws.ws_ship_date_sk
    HAVING SUM(ws.ws_net_profit) > 3000
)
SELECT
    warehouse_id,
    site_key,
    ship_date_sk,
    total_profit,
    order_cnt
FROM billed_sales
UNION ALL
SELECT
    warehouse_id,
    site_key,
    ship_date_sk,
    total_profit,
    order_cnt
FROM shipped_sales
LIMIT 100
