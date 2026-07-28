/*
Goal: Compare net profit from web sales for households that own at least one vehicle with net loss from web returns for households that own no vehicles. For each record also show the household's vehicle count, the web page type, and the average tax amount for that household's sales. Results from the two perspectives are combined with UNION ALL and limited to the first 100 rows.
*/
WITH sales_data AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_profit      AS metric_amount,
        hd.hd_vehicle_count   AS vehicle_count,
        wp.wp_type            AS page_type,
        (
            SELECT avg(ws2.ws_ext_tax)
            FROM tpcds.web_sales ws2
            WHERE ws2.ws_bill_hdemo_sk = hd.hd_demo_sk
        ) AS avg_tax
    FROM tpcds.web_sales ws
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE hd.hd_vehicle_count > 0
      AND wp.wp_type = 'content'
),
returns_data AS (
    SELECT
        wr.wr_order_number  AS order_number,
        -wr.wr_net_loss     AS metric_amount,
        hd.hd_vehicle_count AS vehicle_count,
        wp.wp_type          AS page_type,
        (
            SELECT avg(ws3.ws_ext_tax)
            FROM tpcds.web_sales ws3
            WHERE ws3.ws_bill_hdemo_sk = hd.hd_demo_sk
        ) AS avg_tax
    FROM tpcds.web_returns wr
    JOIN tpcds.household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE hd.hd_vehicle_count = 0
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_sales ws4
            WHERE ws4.ws_order_number = wr.wr_order_number
              AND ws4.ws_ext_tax > 50
        )
)
SELECT *
FROM sales_data
UNION ALL
SELECT *
FROM returns_data
LIMIT 100
