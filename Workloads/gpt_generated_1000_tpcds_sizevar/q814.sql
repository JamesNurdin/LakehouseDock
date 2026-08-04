WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cc.cc_name,
        w.w_warehouse_name,
        w.w_zip,
        ca.ca_city,
        cs.cs_bill_customer_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
),
ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_quantity,
        ws.ws_warehouse_sk,
        w.w_warehouse_name,
        w.w_zip,
        ca.ca_city,
        ws.ws_bill_customer_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
)
SELECT
    COALESCE(cs.cs_order_number, ws.ws_order_number)                     AS order_number,
    COALESCE(cs.cs_warehouse_sk, ws.ws_warehouse_sk)                     AS warehouse_sk,
    COALESCE(cs.w_warehouse_name, ws.w_warehouse_name)                 AS warehouse_name,
    COALESCE(cs.w_zip, ws.w_zip)                                       AS warehouse_zip,
    COALESCE(cs.cs_net_paid_inc_ship, ws.ws_net_paid_inc_ship)         AS net_paid_inc_ship,
    CASE
        WHEN COALESCE(cs.cs_net_paid_inc_ship, ws.ws_net_paid_inc_ship) > 2000 THEN 'High'
        ELSE 'Low'
    END                                                               AS profit_category,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(cs.w_warehouse_name, ws.w_warehouse_name)
        ORDER BY COALESCE(cs.cs_net_paid_inc_ship, ws.ws_net_paid_inc_ship) DESC
    )                                                               AS warehouse_rank,
    (
        SELECT COUNT(DISTINCT cs2.cs_bill_customer_sk)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = COALESCE(cs.cs_warehouse_sk, ws.ws_warehouse_sk)
    )                                                               AS distinct_customers_per_warehouse
FROM cs
FULL OUTER JOIN ws
    ON cs.cs_warehouse_sk = ws.ws_warehouse_sk
WHERE (
        COALESCE(cs.cs_quantity, 0) > 5
        OR COALESCE(ws.ws_quantity, 0) > 3
      )
  AND COALESCE(cs.w_zip, ws.w_zip) LIKE '5%'
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs3
        WHERE cs3.cs_call_center_sk = cs.cs_call_center_sk
          AND cs3.cs_net_profit > 1000
      )
ORDER BY profit_category DESC, net_paid_inc_ship DESC
LIMIT 100
