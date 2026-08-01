WITH sampled_sales AS (
        SELECT *
        FROM web_sales TABLESAMPLE BERNOULLI (10)
    ),
    max_sales AS (
        SELECT max(ws_ext_sales_price) AS max_price
        FROM web_sales
    ),
    first_part AS (
        SELECT sm.sm_ship_mode_id,
               SUM(ws.ws_net_profit) AS total_profit,
               CASE WHEN SUM(ws.ws_net_profit) > (SELECT max_price FROM max_sales)
                    THEN 'HIGH'
                    ELSE 'LOW'
               END AS profit_category
        FROM sampled_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE cd.cd_marital_status = 'M'
          AND ca.ca_suite_number = 'Suite 0   '
        GROUP BY sm.sm_ship_mode_id
    ),
    second_part AS (
        SELECT sm.sm_ship_mode_id,
               SUM(ws.ws_net_profit) AS total_profit,
               CASE WHEN SUM(ws.ws_net_profit) > (SELECT max_price FROM max_sales)
                    THEN 'HIGH'
                    ELSE 'LOW'
               END AS profit_category
        FROM sampled_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
        WHERE cd.cd_marital_status = 'S'
          AND ca.ca_suite_number = 'Suite U   '
        GROUP BY sm.sm_ship_mode_id
    ),
    union_set AS (
        SELECT * FROM first_part
        UNION
        SELECT * FROM second_part
    ),
    intersect_set AS (
        SELECT sm_id FROM (
            SELECT sm.sm_ship_mode_id AS sm_id
            FROM sampled_sales ws
            JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        )
        INTERSECT
        SELECT sm_id FROM (
            SELECT sm.sm_ship_mode_id AS sm_id
            FROM web_sales ws
            JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        )
    ),
    except_set AS (
        SELECT sm_id FROM (
            SELECT sm.sm_ship_mode_id AS sm_id
            FROM web_sales ws
            JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
            GROUP BY sm.sm_ship_mode_id
        )
        EXCEPT
        SELECT sm_id FROM intersect_set
    )
SELECT u.sm_ship_mode_id,
       u.total_profit,
       u.profit_category,
       CASE WHEN i.sm_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS in_intersect,
       CASE WHEN e.sm_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS in_except
FROM union_set u
LEFT JOIN intersect_set i ON u.sm_ship_mode_id = i.sm_id
LEFT JOIN except_set e ON u.sm_ship_mode_id = e.sm_id
ORDER BY u.total_profit DESC
LIMIT 100
