WITH agg_returns AS (
   SELECT
        cp.cp_department,
        i.i_category,
        r.r_reason_desc,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        d_ret.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS num_returns,
        AVG(cr.cr_return_quantity) AS avg_quantity
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   -- Refunded customer details
   JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   -- Returning customer details
   JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
   JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
   JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
   WHERE c_ref.c_birth_country = 'JAPAN'
     AND r.r_reason_sk IN (7, 14, 19)
     AND d_ret.d_year BETWEEN 2000 AND 2002
     AND i.i_color = 'Blue'
     AND sm.sm_carrier = 'UPS'
   GROUP BY
        cp.cp_department,
        i.i_category,
        r.r_reason_desc,
        sm.sm_type,
        w.w_warehouse_name,
        d_ret.d_year
),

agg_web AS (
   SELECT
        i.i_category,
        r.r_reason_desc,
        d_web.d_year,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(*) AS num_web_returns
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
   WHERE i.i_class = 'Electronics'
     AND d_web.d_month_seq BETWEEN 1200 AND 1215
   GROUP BY i.i_category, r.r_reason_desc, d_web.d_year
),

combined AS (
   SELECT
        ar.cp_department,
        ar.i_category,
        ar.r_reason_desc,
        ar.ship_mode_type,
        ar.w_warehouse_name,
        ar.d_year,
        ar.total_return_amount,
        ar.num_returns,
        ar.avg_quantity,
        aw.total_web_return_amount,
        aw.num_web_returns
   FROM agg_returns ar
   LEFT JOIN agg_web aw
       ON ar.i_category = aw.i_category
      AND ar.r_reason_desc = aw.r_reason_desc
      AND ar.d_year = aw.d_year
   WHERE EXISTS (
        SELECT 1
        FROM store s
        JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
        WHERE s.s_state = 'CA'
          AND d_store.d_year = ar.d_year
   )
)

SELECT
    cp_department,
    i_category,
    r_reason_desc,
    ship_mode_type,
    d_year,
    SUM(total_return_amount) AS sum_return_amt,
    SUM(total_web_return_amount) AS sum_web_return_amt,
    SUM(num_returns) AS total_returns,
    SUM(num_web_returns) AS total_web_returns,
    AVG(avg_quantity) AS overall_avg_quantity
FROM combined
GROUP BY GROUPING SETS (
    (cp_department, i_category, r_reason_desc, ship_mode_type, d_year),
    (i_category, d_year),
    ()
)
ORDER BY sum_return_amt DESC
LIMIT 100
