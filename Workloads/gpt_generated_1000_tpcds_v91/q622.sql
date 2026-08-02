WITH joined AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cp.cp_type,
        cp.cp_catalog_page_number,
        sm.sm_code,
        sm.sm_carrier,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM catalog_returns cr
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    INNER JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    INNER JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    INNER JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    INNER JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND sm.sm_code = 'AIR'
      AND sm.sm_carrier NOT IN ('UPS', 'RUPEKSA')
      AND cr.cr_fee > 20
      AND cr.cr_return_ship_cost < 2000
      AND ws.ws_quantity > 1
      AND sm.sm_code IN (
          SELECT sm_code
          FROM (
              SELECT DISTINCT sm.sm_code AS sm_code
              FROM catalog_returns cr2
              JOIN ship_mode sm ON cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
              WHERE cr2.cr_fee > 0
              INTERSECT
              SELECT DISTINCT sm.sm_code
              FROM web_sales ws2
              JOIN ship_mode sm ON ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
              WHERE ws2.ws_quantity > 0
          ) AS intersect_codes
      )
)
SELECT
    sm_code,
    cp_type,
    cp_catalog_page_number,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_quantity,
    SUM(ws_ext_sales_price) AS total_sales_price,
    SUM(ws_net_profit) AS total_net_profit,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        JOIN ship_mode sm2 ON cr2.cr_ship_mode_sk = sm2.sm_ship_mode_sk
        WHERE sm2.sm_code = agg.sm_code
    ) AS avg_return_amount_per_ship_mode
FROM joined AS agg
GROUP BY ROLLUP (sm_code, cp_type, cp_catalog_page_number)
HAVING SUM(cr_return_amount) > 5000
ORDER BY sm_code, cp_type, cp_catalog_page_number
LIMIT 100
