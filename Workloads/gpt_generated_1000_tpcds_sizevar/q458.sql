SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_order_number AS order_number,
    cs.cs_net_paid AS total_sales,
    (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        WHERE sr.sr_customer_sk = cs.cs_bill_customer_sk
    ) AS total_returns,
    w.w_warehouse_name AS location_name
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE w.w_gmt_offset = -5.00
  AND cs.cs_bill_customer_sk IN (
        SELECT sr2.sr_customer_sk
        FROM store_returns sr2
        WHERE sr2.sr_return_amt > 100
    )

UNION

SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_order_number AS order_number,
    ws.ws_net_paid AS total_sales,
    (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        WHERE sr.sr_customer_sk = ws.ws_bill_customer_sk
    ) AS total_returns,
    site.web_name AS location_name
FROM web_sales ws
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
WHERE site.web_county = 'Richland County'
  AND ws.ws_item_sk IN (
        SELECT cs2.cs_item_sk
        FROM catalog_sales cs2
        WHERE cs2.cs_net_profit > 500
    )

ORDER BY total_sales DESC, customer_sk ASC
LIMIT 100
