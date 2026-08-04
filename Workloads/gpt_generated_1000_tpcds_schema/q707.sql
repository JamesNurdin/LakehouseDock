WITH
    sales_agg AS (
        SELECT
            wsit.web_name,
            ca.ca_state,
            SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales
        FROM web_sales ws
        RIGHT OUTER JOIN web_site wsit
            ON ws.ws_web_site_sk = wsit.web_site_sk
        LEFT JOIN customer_address ca
            ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE wsit.web_rec_start_date >= DATE '1999-01-01'
          AND wsit.web_country = 'United States'
          AND ca.ca_country = 'United States'
          AND ws.ws_net_paid_inc_ship_tax > 1000
        GROUP BY ROLLUP (wsit.web_name, ca.ca_state)
    ),
    intersect_keys AS (
        SELECT ca_address_sk
        FROM customer_address
        WHERE ca_state = 'CA' AND ca_country = 'United States'
        INTERSECT
        SELECT ws_bill_addr_sk
        FROM web_sales
        WHERE ws_net_paid_inc_ship_tax > 2000
    ),
    except_keys AS (
        SELECT ca_address_sk
        FROM customer_address
        WHERE ca_state = 'TX' AND ca_country = 'United States'
        EXCEPT
        SELECT ws_ship_addr_sk
        FROM web_sales
        WHERE ws_net_paid_inc_ship_tax > 3000
    ),
    cross_join_set AS (
        SELECT wsit.web_name, v.month_num
        FROM web_site wsit
        CROSS JOIN (VALUES 1,2,3,4,5,6,7,8,9,10,11,12) AS v(month_num)
        WHERE wsit.web_state = 'CA'
          AND wsit.web_name IS NOT NULL
    )
SELECT
    sa.web_name,
    sa.ca_state,
    sa.total_sales,
    (SELECT COUNT(*) FROM intersect_keys) AS intersect_addr_cnt,
    (SELECT COUNT(*) FROM except_keys) AS except_addr_cnt,
    cjs.month_num
FROM sales_agg sa
LEFT JOIN cross_join_set cjs
    ON sa.web_name = cjs.web_name
ORDER BY sa.total_sales DESC
LIMIT 100
