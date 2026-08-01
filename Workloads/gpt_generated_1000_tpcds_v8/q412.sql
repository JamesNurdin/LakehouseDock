WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 500
      AND cr_return_quantity >= 1
),
unioned AS (
    SELECT
        cc.cc_market_manager,
        cp.cp_type,
        hd.hd_vehicle_count,
        cr.cr_return_amount,
        ws.ws_net_profit,
        w.w_warehouse_sk,
        ws.ws_order_number
    FROM filtered_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_sq_ft > 1000000
      AND cp.cp_department = 'Electronics'
      AND hd.hd_buy_potential = '5001-10000'
      AND ws.ws_net_profit > 1000
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_return_amount > cr.cr_return_amount
      )
    UNION
    SELECT
        cc.cc_market_manager,
        cp.cp_type,
        hd.hd_vehicle_count,
        cr.cr_return_amount,
        ws.ws_net_profit,
        w.w_warehouse_sk,
        ws.ws_order_number
    FROM filtered_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_sq_ft > 1000000
      AND cp.cp_department = 'Books'
      AND hd.hd_buy_potential = '1001-5000'
      AND ws.ws_net_profit > 500
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_return_amount > cr.cr_return_amount
      )
),
aggregated AS (
    SELECT
        u.cc_market_manager,
        u.cp_type,
        u.hd_vehicle_count,
        u.w_warehouse_sk,
        u.ws_order_number,
        SUM(u.cr_return_amount) AS total_return_amount,
        AVG(u.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT u.ws_order_number) AS distinct_orders,
        (
            SELECT AVG(ws3.ws_net_paid)
            FROM web_sales ws3
            WHERE ws3.ws_warehouse_sk = u.w_warehouse_sk
              AND ws3.ws_order_number < u.ws_order_number
        ) AS avg_prior_paid
    FROM unioned u
    GROUP BY
        u.cc_market_manager,
        u.cp_type,
        u.hd_vehicle_count,
        u.w_warehouse_sk,
        u.ws_order_number
)
SELECT
    a.cc_market_manager,
    a.cp_type,
    a.hd_vehicle_count,
    a.total_return_amount,
    a.avg_net_profit,
    a.distinct_orders,
    a.avg_prior_paid,
    lr.max_return_amount,
    ROW_NUMBER() OVER (PARTITION BY a.cc_market_manager ORDER BY a.total_return_amount DESC) AS rn
FROM aggregated a
CROSS JOIN LATERAL (
    SELECT MAX(cr5.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr5
    WHERE cr5.cr_warehouse_sk = a.w_warehouse_sk
) AS lr
ORDER BY a.total_return_amount DESC
LIMIT 100
