WITH base_returns AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_returned_time_sk,
       cr.cr_item_sk,
       cr.cr_refunded_addr_sk,
       cr.cr_returning_addr_sk,
       cr.cr_call_center_sk,
       cr.cr_catalog_page_sk,
       cr.cr_ship_mode_sk,
       cr.cr_reason_sk,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       d.d_date,
       d.d_year,
       d.d_quarter_name,
       i.i_item_id,
       i.i_category,
       i.i_brand,
       ca_refunded.ca_city AS refunded_city,
       ca_refunded.ca_state AS refunded_state,
       ca_returning.ca_city AS returning_city,
       ca_returning.ca_state AS returning_state,
       cc.cc_name,
       cc.cc_state AS cc_state,
       cp.cp_department,
       sm.sm_type,
       r.r_reason_desc
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN customer_address ca_refunded
     ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
   JOIN customer_address ca_returning
     ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
   WHERE d.d_year = 1998
     AND i.i_category = 'Sports'
     AND cc.cc_state = 'CA'
     AND sm.sm_type = 'AIR'
     AND r.r_reason_desc = 'Damaged'
)
SELECT
    br.d_date,
    br.cc_name,
    br.i_item_id,
    br.i_category,
    br.i_brand,
    br.return_amount_category,
    br.cr_return_amount,
    br.cr_return_quantity,
    br.cr_net_loss,
    br.return_rank_by_amount,
    br.return_running_total
FROM (
    SELECT
        d_date,
        cc_name,
        i_item_id,
        i_category,
        i_brand,
        CASE
            WHEN cr_return_amount > 1000 THEN 'High'
            WHEN cr_return_amount > 500 THEN 'Medium'
            ELSE 'Low'
        END AS return_amount_category,
        cr_return_amount,
        cr_return_quantity,
        cr_net_loss,
        RANK() OVER (PARTITION BY cc_name ORDER BY cr_return_amount DESC) AS return_rank_by_amount,
        SUM(cr_return_amount) OVER (PARTITION BY cc_name ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS return_running_total
    FROM base_returns
) br
ORDER BY br.cc_name, br.return_rank_by_amount
LIMIT 100
