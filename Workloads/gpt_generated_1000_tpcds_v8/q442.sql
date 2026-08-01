WITH
store_ret AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        dd.d_year,
        i.i_brand,
        s.s_state,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),
catalog_ret AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk,
        dd.d_year,
        i.i_brand,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk,
        dd.d_year,
        i.i_brand,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
),
promo AS (
    SELECT
        p.p_promo_id,
        p.p_item_sk,
        i.i_brand,
        p.p_cost,
        p.p_response_target,
        dd.d_year AS promo_year
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN date_dim dd ON p.p_start_date_sk = dd.d_date_sk
),
call_center_dates AS (
    SELECT
        cc.cc_call_center_sk,
        dd.d_date_sk,
        dd.d_year,
        cc.cc_name,
        cc.cc_state
    FROM call_center cc
    JOIN date_dim dd ON cc.cc_closed_date_sk = dd.d_date_sk
),
catalog_page_dates AS (
    SELECT
        cp.cp_catalog_page_sk,
        dd.d_date_sk,
        dd.d_year,
        cp.cp_department,
        cp.cp_type
    FROM catalog_page cp
    JOIN date_dim dd ON cp.cp_end_date_sk = dd.d_date_sk
),
promo_store_full AS (
    SELECT
        COALESCE(cc.cc_call_center_sk, cp.cp_catalog_page_sk) AS key_id,
        COALESCE(cc.cc_name, cp.cp_department) AS name_or_dept,
        COALESCE(cc.d_year, cp.d_year) AS year,
        cc.cc_state,
        cp.cp_type
    FROM call_center_dates cc
    FULL OUTER JOIN catalog_page_dates cp
        ON cc.d_date_sk = cp.d_date_sk
),
web_site_cte AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        dd.d_year AS open_year,
        ws.web_state
    FROM web_site ws
    JOIN date_dim dd ON ws.web_open_date_sk = dd.d_date_sk
),
union_returns AS (
    SELECT i_brand, d_year, SUM(sr_return_amt) AS total_return
    FROM store_ret
    GROUP BY i_brand, d_year
    UNION
    SELECT i_brand, d_year, SUM(cr_return_amount) AS total_return
    FROM catalog_ret
    GROUP BY i_brand, d_year
),
intersect_brands AS (
    SELECT i_brand FROM store_ret
    INTERSECT
    SELECT i_brand FROM web_ret
),
years AS (
    SELECT DISTINCT d_year FROM date_dim WHERE d_year IN (2000, 2001, 2002) LIMIT 3
),
multipliers AS (
    SELECT * FROM (VALUES (1), (2), (3)) AS t(multiplier)
)
SELECT
    y.d_year,
    ur.i_brand,
    ur.total_return,
    ROW_NUMBER() OVER (PARTITION BY y.d_year ORDER BY ur.total_return DESC) AS brand_rank,
    CASE WHEN ib.i_brand IS NOT NULL THEN 'Both' ELSE 'Single' END AS presence_flag,
    psf.name_or_dept,
    psf.year,
    psf.cc_state,
    psf.cp_type,
    ws.web_name,
    ur.total_return * m.multiplier AS scaled_return,
    (SELECT COUNT(*) FROM store_ret sr2 WHERE sr2.sr_return_amt > 100) AS high_return_cnt
FROM union_returns ur
JOIN years y ON ur.d_year = y.d_year
LEFT JOIN intersect_brands ib ON ur.i_brand = ib.i_brand
LEFT JOIN promo_store_full psf ON ur.d_year = psf.year
LEFT JOIN web_site_cte ws ON ur.d_year = ws.open_year
CROSS JOIN multipliers m
WHERE ur.d_year = 2001
  AND ur.total_return > 500
  AND psf.cc_state = 'TX'
  AND psf.cp_type = 'WEB'
ORDER BY y.d_year, brand_rank, scaled_return DESC
LIMIT 100
