WITH
    store_agg AS (
        SELECT
            sr_store_sk,
            COUNT(*) AS cnt_returns,
            SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
            ARRAY_AGG(sr_return_amt_inc_tax) AS return_amounts
        FROM store_returns
        WHERE sr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim
            WHERE d_year = 2001 AND d_month_seq = 12
        )
        GROUP BY sr_store_sk
    ),
    catalog_agg AS (
        SELECT
            cr_catalog_page_sk,
            COUNT(*) AS cnt_cat_returns,
            SUM(cr_return_amount) AS total_return_amount,
            ARRAY_AGG(cr_return_amount) AS return_amounts_arr
        FROM catalog_returns
        WHERE cr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim
            WHERE d_year = 2001 AND d_month_seq = 12
        )
        GROUP BY cr_catalog_page_sk
    ),
    distinct_catalog_info AS (
        SELECT DISTINCT
            cr_catalog_page_sk,
            cr_ship_mode_sk,
            cr_warehouse_sk
        FROM catalog_returns
        WHERE cr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim
            WHERE d_year = 2001 AND d_month_seq = 12
        )
    ),
    intersect_keys AS (
        SELECT sr_store_sk AS key_sk FROM store_agg
        INTERSECT
        SELECT cr_catalog_page_sk AS key_sk FROM catalog_agg
    )
SELECT
    s.s_store_id,
    cp.cp_catalog_page_id,
    d_main.d_year,
    d_main.d_month_seq,
    SUM(sa.total_return_inc_tax) AS sum_store_return_inc_tax,
    SUM(ca.total_return_amount) AS sum_catalog_return_amount,
    AVG(sa.cnt_returns) AS avg_store_cnt_returns,
    CASE WHEN w.w_gmt_offset >= 0 THEN 'East' ELSE 'West' END AS region_flag,
    t.exploded_amount
FROM intersect_keys ik
JOIN store_agg sa ON ik.key_sk = sa.sr_store_sk
JOIN catalog_agg ca ON ik.key_sk = ca.cr_catalog_page_sk
JOIN store s ON sa.sr_store_sk = s.s_store_sk
JOIN catalog_page cp ON ca.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_main ON s.s_closed_date_sk = d_main.d_date_sk
JOIN distinct_catalog_info dci ON ca.cr_catalog_page_sk = dci.cr_catalog_page_sk
JOIN ship_mode sm ON dci.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON dci.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_main.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_main.d_date_sk
CROSS JOIN UNNEST(sa.return_amounts) AS t(exploded_amount)
WHERE
    s.s_state = 'CA'
    AND w.w_city = 'Washington 7th'
    AND sm.sm_carrier = 'UPS'
    AND cp.cp_department = 'Electronics'
    AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_amt_inc_tax > 500
    )
GROUP BY
    s.s_store_id,
    cp.cp_catalog_page_id,
    d_main.d_year,
    d_main.d_month_seq,
    CASE WHEN w.w_gmt_offset >= 0 THEN 'East' ELSE 'West' END,
    t.exploded_amount
ORDER BY sum_store_return_inc_tax DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
