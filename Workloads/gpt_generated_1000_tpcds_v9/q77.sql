WITH
    calc_numbers AS (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    ),
    small_ib AS (
        SELECT DISTINCT ib_income_band_sk FROM income_band
    ),
    call_center_filtered AS (
        SELECT DISTINCT cc.cc_call_center_sk, cc.cc_name
        FROM call_center cc
        JOIN date_dim dcc ON cc.cc_closed_date_sk = dcc.d_date_sk
        WHERE dcc.d_year = 2002
    )
SELECT
    s.s_store_name,
    i.i_category,
    i.i_brand,
    ccf.cc_name AS call_center_name,
    cp.cp_type,
    d_sold.d_year,
    sb_ib.ib_income_band_sk,
    n.n AS cross_num,
    wp.wp_url,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > COALESCE(SUM(cr.cr_return_amount), 0) THEN 'Net Profit'
        ELSE 'Net Loss'
    END AS profit_flag,
    (SELECT MAX(d_year) FROM date_dim WHERE d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31') AS latest_year
FROM
    store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd_sold ON ss.ss_hdemo_sk = hd_sold.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN call_center_filtered ccf ON cr.cr_call_center_sk = ccf.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    CROSS JOIN small_ib sb_ib
    CROSS JOIN calc_numbers n
WHERE
    d_sold.d_year = 2002
    AND EXISTS (
        SELECT 1 FROM call_center_filtered cc_check WHERE cc_check.cc_name = ccf.cc_name
    )
GROUP BY
    s.s_store_name,
    i.i_category,
    i.i_brand,
    ccf.cc_name,
    cp.cp_type,
    d_sold.d_year,
    sb_ib.ib_income_band_sk,
    n.n,
    wp.wp_url
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
ORDER BY
    total_sales DESC
LIMIT 100
