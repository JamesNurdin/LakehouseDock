WITH
    -- Aggregate inventory per item and date (pre‑aggregation CTE)
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_item_sk, inv_date_sk
    ),
    -- Sales aggregated by call centre, date and household demographics
    sales_agg AS (
        SELECT
            cc.cc_call_center_id,
            d.d_year,
            d.d_date_sk,
            SUM(cs.cs_net_paid_inc_tax) AS total_sales,
            COUNT(*) AS sales_cnt,
            AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE d.d_year = 2000
          AND d.d_current_month = 'Y'
          AND cs.cs_net_paid_inc_tax > 1000
          AND hd.hd_vehicle_count > 0
        GROUP BY cc.cc_call_center_id, d.d_year, d.d_date_sk
    ),
    -- Store‑return aggregation
    store_ret_agg AS (
        SELECT
            r.r_reason_desc,
            d.d_year,
            d.d_date_sk,
            SUM(sr.sr_net_loss) AS total_loss,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
          AND r.r_reason_desc NOT LIKE '%unknown%'
        GROUP BY r.r_reason_desc, d.d_year, d.d_date_sk
    ),
    -- Web‑return aggregation
    web_ret_agg AS (
        SELECT
            r.r_reason_desc,
            d.d_year,
            d.d_date_sk,
            SUM(wr.wr_net_loss) AS total_loss,
            COUNT(*) AS return_cnt
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
          AND r.r_reason_desc NOT LIKE '%unknown%'
        GROUP BY r.r_reason_desc, d.d_year, d.d_date_sk
    ),
    -- Union of the two return streams (set operation)
    returns_union AS (
        SELECT * FROM store_ret_agg
        UNION ALL
        SELECT * FROM web_ret_agg
    ),
    -- Web‑page aggregation (required to involve the web_page table)
    web_page_agg AS (
        SELECT
            wp.wp_web_page_id,
            d.d_date_sk,
            COUNT(*) AS page_views
        FROM web_page wp
        JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
          AND wp.wp_type = 'home'
        GROUP BY wp.wp_web_page_id, d.d_date_sk
    )
SELECT
    s.cc_call_center_id,
    s.d_year,
    s.total_sales,
    s.sales_cnt,
    s.avg_vehicle_cnt,
    r.r_reason_desc,
    r.total_loss,
    r.return_cnt,
    wp.wp_web_page_id,
    wp.page_views,
    i.total_on_hand
FROM sales_agg s
JOIN returns_union r ON s.d_date_sk = r.d_date_sk
JOIN inv_agg i ON r.d_date_sk = i.inv_date_sk
JOIN web_page_agg wp ON s.d_date_sk = wp.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM reason rr
    WHERE rr.r_reason_desc = r.r_reason_desc
      AND rr.r_reason_desc LIKE '%test%'
)
ORDER BY s.total_sales DESC, r.total_loss ASC
LIMIT 100
