WITH agg_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk
)
SELECT
    s.s_store_name,
    s.s_state,
    r.r_reason_desc,
    ca_sr.ca_city,
    t1.t_hour,
    wp.wp_type,
    cp_l.cp_department,
    cp_l.sm_type,
    cp_l.dept_sales,
    cp_l.dept_cnt,
    ar.total_loss,
    ca_wr_ref.ca_state AS refunded_state
FROM store s
FULL OUTER JOIN store_returns sr
    ON s.s_store_sk = sr.sr_store_sk
LEFT JOIN time_dim t1
    ON sr.sr_return_time_sk = t1.t_time_sk
LEFT JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN agg_returns ar
    ON s.s_store_sk = ar.sr_store_sk
   AND r.r_reason_sk = ar.sr_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = t1.t_time_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
LEFT JOIN customer_address ca_wr_ref
    ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
CROSS JOIN LATERAL (
    SELECT
        cp.cp_department,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS dept_sales,
        COUNT(*) AS dept_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_call_center_id = s.s_store_id
    GROUP BY cp.cp_department, sm.sm_type
    ORDER BY dept_sales DESC
    LIMIT 1
) AS cp_l
WHERE ca_sr.ca_state IN (
    SELECT ca1.ca_state
    FROM customer_address ca1
    JOIN store_returns sr1 ON sr1.sr_addr_sk = ca1.ca_address_sk
    WHERE sr1.sr_return_quantity > 5
    INTERSECT
    SELECT ca2.ca_state
    FROM customer_address ca2
    JOIN web_returns wr1 ON wr1.wr_refunded_addr_sk = ca2.ca_address_sk
    WHERE wr1.wr_return_quantity > 3
)
  AND s.s_store_id NOT IN (
    SELECT s3.s_store_id FROM store s3 WHERE s3.s_number_employees < 10
)
ORDER BY s.s_store_name
LIMIT 100
