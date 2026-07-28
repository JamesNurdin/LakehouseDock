WITH returns_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_refunded_addr_sk,
        cr_returning_addr_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_warehouse_sk,
        SUM(cr_return_amount)     AS total_return_amount,
        SUM(cr_return_ship_cost) AS total_ship_cost,
        COUNT(*)                 AS return_cnt
    FROM catalog_returns
    WHERE cr_return_ship_cost > 100
      AND cr_return_amount > 500
    GROUP BY
        cr_returned_date_sk,
        cr_refunded_addr_sk,
        cr_returning_addr_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_warehouse_sk
)
SELECT
    d_ret.d_year,
    cc.cc_name,
    w.w_warehouse_name,
    cp.cp_department,
    SUM(ra.total_return_amount) AS sum_return_amount,
    AVG(ra.total_return_amount) AS avg_return_amount,
    SUM(ra.return_cnt)          AS total_returns,
    MAX(ra.total_ship_cost)     AS max_ship_cost
FROM returns_agg ra
JOIN date_dim d_ret               ON ra.cr_returned_date_sk   = d_ret.d_date_sk
JOIN call_center cc               ON ra.cr_call_center_sk     = cc.cc_call_center_sk
JOIN catalog_page cp              ON ra.cr_catalog_page_sk    = cp.cp_catalog_page_sk
JOIN warehouse w                  ON ra.cr_warehouse_sk       = w.w_warehouse_sk
JOIN customer_address ca_refunded ON ra.cr_refunded_addr_sk   = ca_refunded.ca_address_sk
JOIN customer_address ca_returning ON ra.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_site ws                  ON ws.web_open_date_sk     = d_ret.d_date_sk
WHERE d_ret.d_year = 2001
  AND d_ret.d_qoy = 1
  AND cp.cp_catalog_number IN (1, 4, 10)
  AND ca_refunded.ca_state = 'CA'
  AND w.w_warehouse_sq_ft > 2000
  AND ws.web_tax_percentage < 5.0
GROUP BY d_ret.d_year, cc.cc_name, w.w_warehouse_name, cp.cp_department
ORDER BY sum_return_amount DESC
LIMIT 100
