WITH filtered_warehouses AS (
    SELECT w_warehouse_sk, w_city
    FROM warehouse
    WHERE w_state = 'CA'
)
SELECT
    cc.cc_name,
    ws.web_name,
    d_ret.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(cr.cr_return_amount) DESC) AS return_rank
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN filtered_warehouses fw ON w_ret.w_warehouse_sk = fw.w_warehouse_sk
JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w_ret.w_warehouse_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_wc ON ws.web_close_date_sk = d_wc.d_date_sk
WHERE td.t_sub_shift = 'morning'
  AND d_ret.d_year = 2001
  AND cc.cc_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_gender = 'M'
          AND cd2.cd_education_status = 'College'
          AND cd2.cd_demo_sk = cr.cr_returning_cdemo_sk
      )
  AND s.s_store_name IN (
        SELECT s2.s_store_name
        FROM store s2
        WHERE s2.s_state = 'CA'
      )
GROUP BY
    cc.cc_name,
    ws.web_name,
    d_ret.d_year
ORDER BY
    total_return_amount DESC,
    cc.cc_name
LIMIT 100
