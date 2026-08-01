WITH store_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS sub_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'High' ELSE 'Low' END AS sales_volume_category,
        'store' AS source
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate > 1000
    GROUP BY ROLLUP (cd.cd_gender, cd.cd_education_status)
),

web_agg AS (
    SELECT
        cd.cd_gender AS gender,
        sm.sm_carrier AS sub_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        CASE WHEN SUM(ws.ws_quantity) > 200 THEN 'High' ELSE 'Low' END AS sales_volume_category,
        'web' AS source
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE sm.sm_carrier = 'FEDEX'
      AND wh.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_net_loss > 0
      )
    GROUP BY ROLLUP (cd.cd_gender, sm.sm_carrier)
)

SELECT
    gender,
    sub_category,
    total_net_paid,
    num_transactions,
    sales_volume_category,
    source,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS global_rank,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_net_paid DESC) AS source_rank,
    SUM(total_net_paid) OVER (PARTITION BY gender) AS gender_total_net_paid,
    (SELECT MAX(cd_purchase_estimate) FROM customer_demographics) AS max_purchase_estimate
FROM (
    SELECT
        gender,
        sub_category,
        total_net_paid,
        num_tickets AS num_transactions,
        sales_volume_category,
        source
    FROM store_agg
    UNION ALL
    SELECT
        gender,
        sub_category,
        total_net_paid,
        num_orders AS num_transactions,
        sales_volume_category,
        source
    FROM web_agg
) u
ORDER BY total_net_paid DESC
