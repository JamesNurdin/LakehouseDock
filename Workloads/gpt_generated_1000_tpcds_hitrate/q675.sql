WITH web_branch AS (
    SELECT
        'web' AS source,
        site.web_name AS key_name,
        ws.ws_net_paid AS metric,
        ws.ws_quantity AS qty
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN tpcds.customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    RIGHT JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr
        WHERE cr.cr_order_number = ws.ws_order_number
          AND cr.cr_return_amount > 0
    )
),
store_branch AS (
    SELECT
        'store' AS source,
        s.s_store_name AS key_name,
        ss.ss_net_paid AS metric,
        ss.ss_quantity AS qty
    FROM tpcds.store_sales ss
    FULL OUTER JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
),
catalog_branch AS (
    SELECT
        'catalog' AS source,
        cp.cp_department AS key_name,
        cr.cr_return_amount AS metric,
        cr.cr_return_quantity AS qty
    FROM tpcds.catalog_returns cr
    RIGHT OUTER JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.ship_mode sm2
        ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
)
SELECT
    source,
    key_name,
    SUM(metric) AS total_metric,
    SUM(CASE WHEN qty > 5 THEN metric ELSE metric * 0.5 END) AS adjusted_metric,
    COUNT(*) AS row_count
FROM (
    SELECT * FROM web_branch
    UNION ALL
    SELECT * FROM store_branch
    UNION ALL
    SELECT * FROM catalog_branch
) all_data
GROUP BY GROUPING SETS (
    (source, key_name),
    (source),
    ()
)
LIMIT 100
