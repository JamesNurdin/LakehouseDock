WITH ws_lateral AS (
    SELECT ws.*
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ws.ws_quantity > 1
)
SELECT
    ws_lateral.ws_web_site_sk,
    web_site.web_name,
    item.i_category,
    COUNT(DISTINCT ws_lateral.ws_order_number)               AS order_cnt,
    SUM(ws_lateral.ws_ext_sales_price)                        AS total_web_sales,
    SUM(cs.cs_ext_sales_price)                                AS total_catalog_sales,
    AVG(cs.cs_net_profit)                                     AS avg_catalog_profit,
    SUM(cr.cr_return_amount)                                  AS total_return_amount,
    COUNT(DISTINCT cr.cr_reason_sk)                           AS distinct_return_reasons
FROM web_site
CROSS JOIN LATERAL (
    SELECT *
    FROM ws_lateral
    WHERE ws_lateral.ws_web_site_sk = web_site.web_site_sk
) AS ws_lateral
JOIN item
    ON ws_lateral.ws_item_sk = item.i_item_sk
JOIN household_demographics hd_ws
    ON ws_lateral.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN customer_address ca_ws
    ON ws_lateral.ws_bill_addr_sk = ca_ws.ca_address_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = item.i_item_sk
   AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
JOIN call_center
    ON cs.cs_call_center_sk = call_center.cc_call_center_sk
JOIN customer_address ca_cs
    ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = item.i_item_sk
JOIN reason
    ON cr.cr_reason_sk = reason.r_reason_sk
JOIN household_demographics hd_cr_refunded
    ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN customer_address ca_cr_refunded
    ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
WHERE
    call_center.cc_market_manager = 'Scott Bryant'
    AND web_site.web_market_manager = 'James Harris'
    AND web_site.web_state IN ('NY', 'CO', 'WV')
    AND reason.r_reason_desc LIKE '%color%'
    AND hd_ws.hd_income_band_sk = 15
    AND ca_ws.ca_zip LIKE '98%'
    AND hd_ws.hd_vehicle_count >= 1
    AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = cr.cr_reason_sk
          AND r2.r_reason_id = 'AAAAAAAAGAAAAAAA'
    )
GROUP BY
    ws_lateral.ws_web_site_sk,
    web_site.web_name,
    item.i_category
HAVING COUNT(DISTINCT ws_lateral.ws_order_number) > 10
ORDER BY total_web_sales DESC
LIMIT 100
