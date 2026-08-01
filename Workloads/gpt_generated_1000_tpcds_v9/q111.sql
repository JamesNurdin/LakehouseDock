SELECT *
FROM (
    SELECT
        'catalog' AS source,
        cp.cp_department AS department,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
        SUM(cs.cs_net_paid_inc_ship) AS total_amount,
        COUNT(*) AS order_count,
        EXISTS (
            SELECT 1
            FROM ship_mode sm_check
            WHERE sm_check.sm_carrier = 'UPS'
              AND sm_check.sm_contract = '5FKNB0j8aaqTB'
        ) AS has_ups_contract
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE sm.sm_carrier = 'UPS'
      AND cs.cs_net_paid_inc_ship > (
          SELECT avg(cs2.cs_net_paid_inc_ship)
          FROM catalog_sales cs2
      )
    GROUP BY
        cp.cp_department,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END
    UNION ALL
    SELECT
        'web_return' AS source,
        wp.wp_type AS department,
        CASE WHEN wr.wr_return_quantity > 3 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
        SUM(wr.wr_net_loss) AS total_amount,
        COUNT(*) AS order_count,
        EXISTS (
            SELECT 1
            FROM ship_mode sm_check
            WHERE sm_check.sm_carrier = 'UPS'
              AND sm_check.sm_contract = '5FKNB0j8aaqTB'
        ) AS has_ups_contract
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_type IN ('blog', 'home')
    GROUP BY
        wp.wp_type,
        CASE WHEN wr.wr_return_quantity > 3 THEN 'Bulk' ELSE 'Regular' END
) AS combined
ORDER BY total_amount DESC, source ASC
LIMIT 100
