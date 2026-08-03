WITH sr_agg AS (
    SELECT
        sr_store_sk,
        sr_item_sk,
        sr_hdemo_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns,
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY sr_store_sk, sr_item_sk, sr_hdemo_sk
    HAVING SUM(sr_return_quantity) > 10
),
catalog_page_dt AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        d_cp.d_date_sk
    FROM catalog_page cp
    JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
),
web_page_dt AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        d_wp.d_date_sk
    FROM web_page wp
    JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
)
SELECT
    store.s_store_name,
    item.i_brand,
    hd.hd_vehicle_count,
    cc.cc_name,
    SUM(sr_agg.total_return_amt) AS sum_store_return_amt,
    COUNT(DISTINCT cr.cr_order_number) AS cnt_catalog_orders,
    CASE WHEN SUM(sr_agg.total_return_qty) > 100 THEN 'HIGH' ELSE 'LOW' END AS return_volume_category,
    (SELECT MAX(d2.d_year) FROM date_dim d2 WHERE d2.d_year < 2000) AS max_year_before_2000,
    catalog_page_dt.cp_department,
    web_page_dt.wp_type
FROM sr_agg
JOIN store ON sr_agg.sr_store_sk = store.s_store_sk
JOIN date_dim d_store_closed ON store.s_closed_date_sk = d_store_closed.d_date_sk
JOIN item ON sr_agg.sr_item_sk = item.i_item_sk
JOIN household_demographics hd ON sr_agg.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_item_sk = item.i_item_sk
JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
FULL OUTER JOIN catalog_page_dt ON catalog_page_dt.d_date_sk = d_cr_return.d_date_sk
FULL OUTER JOIN web_page_dt ON web_page_dt.d_date_sk = d_cr_return.d_date_sk
WHERE
    store.s_state = 'CA'
    AND item.i_brand_id IN (1001001, 8007005)
    AND cc.cc_market_manager = 'John Doe'
    AND d_store_closed.d_year = 2001
    AND hd.hd_vehicle_count >= 2
GROUP BY
    store.s_store_name,
    item.i_brand,
    hd.hd_vehicle_count,
    cc.cc_name,
    catalog_page_dt.cp_department,
    web_page_dt.wp_type
HAVING
    SUM(sr_agg.total_return_amt) > 1000
ORDER BY sum_store_return_amt DESC
LIMIT 100
