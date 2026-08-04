WITH sales_agg AS (
   SELECT ss.ss_sold_date_sk,
          td.t_shift,
          SUM(ss.ss_net_paid) AS total_sales
   FROM store_sales ss
   RIGHT OUTER JOIN time_dim td
     ON ss.ss_sold_time_sk = td.t_time_sk
   GROUP BY ss.ss_sold_date_sk, td.t_shift
)
SELECT *
FROM (
   SELECT
       cc1.cc_company_name        AS company_name,
       td2.t_shift                AS shift,
       w1.w_state                 AS warehouse_state,
       SUM(sa.total_sales)        AS sales_amount,
       SUM(cr1.cr_return_amount) AS return_amount
   FROM catalog_returns cr1
   JOIN time_dim td2
     ON cr1.cr_returned_time_sk = td2.t_time_sk
   JOIN call_center cc1
     ON cr1.cr_call_center_sk = cc1.cc_call_center_sk
   JOIN warehouse w1
     ON cr1.cr_warehouse_sk = w1.w_warehouse_sk
   CROSS JOIN sales_agg sa
   CROSS JOIN catalog_returns cr2
   JOIN time_dim td3
     ON cr2.cr_returned_time_sk = td3.t_time_sk
   JOIN call_center cc2
     ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
   JOIN warehouse w2
     ON cr2.cr_warehouse_sk = w2.w_warehouse_sk
   WHERE td2.t_shift = 'first'
   GROUP BY cc1.cc_company_name, td2.t_shift, w1.w_state

   UNION DISTINCT

   SELECT
       cc1.cc_company_name,
       td2.t_shift,
       w1.w_state,
       SUM(sa.total_sales),
       SUM(cr1.cr_return_amount)
   FROM catalog_returns cr1
   JOIN time_dim td2
     ON cr1.cr_returned_time_sk = td2.t_time_sk
   JOIN call_center cc1
     ON cr1.cr_call_center_sk = cc1.cc_call_center_sk
   JOIN warehouse w1
     ON cr1.cr_warehouse_sk = w1.w_warehouse_sk
   CROSS JOIN sales_agg sa
   CROSS JOIN catalog_returns cr2
   JOIN time_dim td3
     ON cr2.cr_returned_time_sk = td3.t_time_sk
   JOIN call_center cc2
     ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
   JOIN warehouse w2
     ON cr2.cr_warehouse_sk = w2.w_warehouse_sk
   WHERE td2.t_shift = 'second'
   GROUP BY cc1.cc_company_name, td2.t_shift, w1.w_state
) AS combined
ORDER BY combined.sales_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
