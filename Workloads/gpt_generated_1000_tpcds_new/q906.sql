WITH base1 AS (
    SELECT
        cc.cc_call_center_id,
        w.w_warehouse_name,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        inv.inv_quantity_on_hand,
        CASE WHEN cr.cr_return_amount > (
                SELECT avg(cr2.cr_return_amount)
                FROM tpcds.catalog_returns cr2
            ) THEN 'HIGH' ELSE 'LOW' END AS return_level,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY cr.cr_return_amount DESC) AS rn_state,
        RANK() OVER (PARTITION BY cc.cc_state ORDER BY cr.cr_return_amount DESC) AS rnk_state
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN (
        SELECT *
        FROM tpcds.inventory
        TABLESAMPLE BERNOULLI (10)
    ) inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_city = 'Hickory'
      AND cc.cc_zip = '12345'
      AND w.w_state = 'CA'
      AND cr.cr_return_ship_cost > 5
      AND cr.cr_fee > 0
      AND ws.ws_ext_list_price > 1000
      AND inv.inv_quantity_on_hand < 500
),
base2 AS (
    SELECT
        cc.cc_call_center_id,
        w.w_warehouse_name,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        inv.inv_quantity_on_hand,
        CASE WHEN cr.cr_return_amount > (
                SELECT avg(cr2.cr_return_amount)
                FROM tpcds.catalog_returns cr2
            ) THEN 'HIGH' ELSE 'LOW' END AS return_level,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY cr.cr_return_amount DESC) AS rn_state,
        RANK() OVER (PARTITION BY cc.cc_state ORDER BY cr.cr_return_amount DESC) AS rnk_state
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN (
        SELECT *
        FROM tpcds.inventory
        TABLESAMPLE BERNOULLI (10)
    ) inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_city = 'River'
      AND cc.cc_zip = '67890'
      AND w.w_state = 'CA'
      AND cr.cr_return_ship_cost BETWEEN 1 AND 20
      AND cr.cr_fee > 0
      AND ws.ws_ext_list_price BETWEEN 500 AND 2000
      AND inv.inv_quantity_on_hand BETWEEN 200 AND 1000
)
SELECT
    u.cc_call_center_id,
    u.w_warehouse_name,
    u.cr_return_amount,
    u.ws_ext_sales_price,
    u.inv_quantity_on_hand,
    u.return_level,
    u.rn_state,
    u.rnk_state
FROM (
    SELECT * FROM base1
    UNION
    SELECT * FROM base2
) u
WHERE u.rn_state <= 10
ORDER BY u.cr_return_amount DESC
LIMIT 100
