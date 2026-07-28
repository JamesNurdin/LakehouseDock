WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_sales_net_paid,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(cr.cr_return_amount) AS total_catalog_return_amt,
        (SELECT MAX(cc2.cc_gmt_offset)
         FROM call_center cc2
         WHERE cc2.cc_division = s.s_division_id) AS max_cc_gmt_offset,
        (SELECT COUNT(DISTINCT cc3.cc_call_center_id)
         FROM call_center cc3
         WHERE cc3.cc_division = s.s_division_id) AS distinct_cc_count
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND s.s_market_manager IN ('David Smith', 'John Sizemore')
      AND cp.cp_catalog_number IN (1, 4, 7)
      AND t.t_sub_shift = 'morning'
      AND sm.sm_type = 'AIR'
    GROUP BY d.d_year, s.s_store_id, s.s_store_name, s.s_division_id
)
SELECT
    d_year,
    s_store_id,
    s_store_name,
    total_sales_net_paid,
    total_store_return_amt,
    total_catalog_return_amt,
    max_cc_gmt_offset,
    distinct_cc_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales_net_paid DESC) AS sales_rank
FROM base
ORDER BY d_year, sales_rank
LIMIT 100
