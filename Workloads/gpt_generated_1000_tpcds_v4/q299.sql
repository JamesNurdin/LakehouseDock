WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY ss.ss_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_income_band_sk,
    r.r_reason_desc,
    sm.sm_type,
    cp.cp_department,
    cc.cc_name,
    td.t_hour,
    sr.sr_return_quantity,
    cr.cr_return_quantity,
    wr.wr_return_quantity,
    agg.total_sales,
    CASE WHEN agg.total_sales > 500000 THEN 'High' ELSE 'Low' END AS sales_category,
    RANK() OVER (PARTITION BY s.s_state ORDER BY agg.total_sales DESC) AS state_sales_rank,
    (
        SELECT AVG(sr_inner.sr_net_loss)
        FROM store_returns sr_inner
        WHERE sr_inner.sr_reason_sk = sr.sr_reason_sk
    ) AS avg_loss_by_reason
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_return_time_sk = td.t_time_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
    AND cr.cr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_reason_sk = r.r_reason_sk
JOIN store_sales_agg agg ON agg.ss_store_sk = s.s_store_sk
WHERE
    td.t_hour BETWEEN 9 AND 17
    AND s.s_state = 'CA'
    AND cc.cc_name LIKE '%Center%'
ORDER BY agg.total_sales DESC
LIMIT 100
