WITH filtered_call_centers AS (
       SELECT cc.cc_call_center_sk,
              cc.cc_call_center_id,
              cc.cc_name,
              cc.cc_state
       FROM call_center cc
       WHERE cc.cc_country = 'United States'
         AND cc.cc_state IN ('MI', 'WA')
   ),
   sales_agg AS (
       SELECT fc.cc_call_center_id   AS call_center_id,
              fc.cc_name            AS call_center_name,
              d.d_month_seq        AS month_seq,
              SUM(cs.cs_ext_sales_price) AS metric_amount,
              'sales'               AS metric_type
       FROM catalog_sales cs
       JOIN filtered_call_centers fc
         ON cs.cs_call_center_sk = fc.cc_call_center_sk
       JOIN date_dim d
         ON cs.cs_sold_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
       GROUP BY fc.cc_call_center_id, fc.cc_name, d.d_month_seq
   ),
   returns_agg AS (
       SELECT fc.cc_call_center_id   AS call_center_id,
              fc.cc_name            AS call_center_name,
              d.d_month_seq        AS month_seq,
              SUM(cr.cr_return_amount) AS metric_amount,
              'returns'            AS metric_type
       FROM catalog_returns cr
       JOIN filtered_call_centers fc
         ON cr.cr_call_center_sk = fc.cc_call_center_sk
       JOIN date_dim d
         ON cr.cr_returned_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
       GROUP BY fc.cc_call_center_id, fc.cc_name, d.d_month_seq
   )
SELECT call_center_id,
       call_center_name,
       month_seq,
       metric_amount,
       metric_type
FROM sales_agg
UNION ALL
SELECT call_center_id,
       call_center_name,
       month_seq,
       metric_amount,
       metric_type
FROM returns_agg
ORDER BY call_center_id, month_seq, metric_type
LIMIT 100
