WITH filtered_store_keys AS (
        SELECT s_store_sk
        FROM store
        WHERE s_state = 'CA'
    ),
    brand_subset AS (
        SELECT DISTINCT i_brand
        FROM item
        WHERE i_brand_id < 5
    ),
    seq_vals AS (
        SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3
    )
SELECT
    s.s_store_id,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    cp.cp_department,
    r.r_reason_desc,
    w.w_warehouse_name,
    sm.sm_type AS ship_mode_type,
    ws.ws_net_paid,
    SUM(cs.cs_ext_sales_price) OVER (
        PARTITION BY i.i_item_sk
        ORDER BY cs.cs_sold_date_sk
        ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
    ) AS moving_30day_sales,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_store_sk
        ORDER BY cs.cs_ext_sales_price DESC
    ) AS store_item_sales_rank,
    CASE
        WHEN hd.hd_income_band_sk >= 10 THEN 'High'
        ELSE 'Low'
    END AS income_band_category,
    b.i_brand AS cross_brand,
    seq.seq AS cross_seq
FROM
    store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    CROSS JOIN brand_subset b
    CROSS JOIN seq_vals seq
WHERE
    ss.ss_store_sk IN (SELECT s_store_sk FROM filtered_store_keys)
    AND w.w_state IN ('MI', 'GA')
    AND w.w_gmt_offset = -5.00
    AND hd.hd_income_band_sk BETWEEN 5 AND 15
    AND i.i_current_price > 20
    AND s.s_market_id = 5
    AND r.r_reason_desc LIKE '%damage%'
ORDER BY
    store_item_sales_rank,
    moving_30day_sales DESC
LIMIT 100
