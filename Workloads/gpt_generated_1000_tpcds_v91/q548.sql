WITH
    common_customers AS (
        SELECT cr.cr_returning_customer_sk AS c_customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 2000
        INTERSECT
        SELECT ws.ws_bill_customer_sk
        FROM web_sales ws
        WHERE ws.ws_net_paid > 1500
    ),
    filtered AS (
        SELECT
            cc.cc_company AS cc_company,
            ca.ca_state AS ca_state,
            hd.hd_vehicle_count AS hd_vehicle_count,
            hd.hd_dep_count AS hd_dep_count,
            r.r_reason_desc AS r_reason_desc,
            t.t_hour AS t_hour,
            SUM(cr.cr_return_amount) AS total_return_amount,
            SUM(ws.ws_net_paid) AS total_net_paid,
            COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
            AVG(ws.ws_net_profit) AS avg_net_profit,
            MIN(ws.ws_sales_price) AS min_sales_price,
            MAX(ws.ws_sales_price) AS max_sales_price
        FROM
            call_center cc
            FULL OUTER JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
            LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
            LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
            LEFT JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
            LEFT JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
            LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
            LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
            LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                AND sr.sr_return_time_sk = t.t_time_sk
                AND sr.sr_hdemo_sk = hd.hd_demo_sk
                AND sr.sr_addr_sk = ca.ca_address_sk
                AND sr.sr_reason_sk = r.r_reason_sk
            LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                AND ws.ws_sold_time_sk = t.t_time_sk
                AND ws.ws_warehouse_sk = w.w_warehouse_sk
                AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                AND ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE
            ca.ca_state = 'CA'
            AND cc.cc_company = 4
            AND hd.hd_vehicle_count >= 2
            AND hd.hd_dep_count <= 3
            AND r.r_reason_desc LIKE '%defect%'
            AND t.t_hour BETWEEN 9 AND 17
            AND c.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
        GROUP BY
            cc.cc_company,
            ca.ca_state,
            hd.hd_vehicle_count,
            hd.hd_dep_count,
            r.r_reason_desc,
            t.t_hour
    )
SELECT
    cc_company,
    ca_state,
    hd_vehicle_count,
    hd_dep_count,
    r_reason_desc,
    t_hour,
    total_return_amount,
    total_net_paid,
    distinct_customers,
    avg_net_profit,
    min_sales_price,
    max_sales_price,
    (SELECT MAX(cr_return_amount) FROM catalog_returns) AS overall_max_return,
    SUM(total_return_amount) OVER (PARTITION BY ca_state ORDER BY t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_by_state,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_return_amount DESC) AS revenue_rank
FROM filtered
ORDER BY total_return_amount DESC
LIMIT 100
