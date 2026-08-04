WITH cr_agg AS (
    SELECT
        cr_warehouse_sk,
        cr_call_center_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 500
      AND cr_return_quantity >= 1
      AND cr_fee < 200
      AND cr_refunded_cash > 100
      AND cr_reversed_charge < 100
    GROUP BY cr_warehouse_sk, cr_call_center_sk
),
ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_web_site_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_net_paid > 1000
      AND ws_quantity >= 1
      AND ws_ext_discount_amt < 500
      AND ws_ext_ship_cost < 200
      AND ws_coupon_amt = 0
    GROUP BY ws_warehouse_sk, ws_web_site_sk
),
cr_detail AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        cr_agg.total_return_amount,
        cr_agg.return_cnt,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk
    FROM cr_agg
    JOIN catalog_returns cr
        ON cr_agg.cr_warehouse_sk = cr.cr_warehouse_sk
       AND cr_agg.cr_call_center_sk = cr.cr_call_center_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
),
ws_detail AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ws_agg.total_net_paid,
        ws_agg.sales_cnt,
        ws.ws_warehouse_sk
    FROM ws_agg
    JOIN web_sales ws
        ON ws_agg.ws_warehouse_sk = ws.ws_warehouse_sk
       AND ws_agg.ws_web_site_sk = ws.ws_web_site_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
)
SELECT
    COALESCE(cd.ca_address_sk, wd.ca_address_sk) AS address_sk,
    COALESCE(cd.ca_city, wd.ca_city) AS city,
    COALESCE(cd.ca_state, wd.ca_state) AS state,
    COALESCE(cd.total_return_amount, 0) AS total_return_amount,
    COALESCE(cd.return_cnt, 0) AS return_cnt,
    COALESCE(wd.total_net_paid, 0) AS total_net_paid,
    COALESCE(wd.sales_cnt, 0) AS sales_cnt,
    cc.cc_name,
    w.w_warehouse_name,
    (COALESCE(cd.total_return_amount, 0) + COALESCE(wd.total_net_paid, 0)) AS combined_amount
FROM cr_detail cd
FULL OUTER JOIN ws_detail wd
    ON cd.ca_address_sk = wd.ca_address_sk
LEFT JOIN call_center cc
    ON cd.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w
    ON COALESCE(cd.cr_warehouse_sk, wd.ws_warehouse_sk) = w.w_warehouse_sk
WHERE (cc.cc_tax_percentage IS NOT NULL AND cc.cc_tax_percentage < 0.10)
  AND (w.w_state IN ('GA', 'OH', 'MN'))
  AND (COALESCE(cd.total_return_amount, 0) + COALESCE(wd.total_net_paid, 0) > 1000)
  AND (COALESCE(cd.ca_city, wd.ca_city) IS NOT NULL)
  AND (COALESCE(cd.ca_state, wd.ca_state) <> 'TX')
ORDER BY combined_amount DESC
LIMIT 100
