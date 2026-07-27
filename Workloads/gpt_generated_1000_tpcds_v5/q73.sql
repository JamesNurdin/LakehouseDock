WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_size,
        w.w_warehouse_name,
        ws.ws_sold_date_sk AS date_sk,
        s.web_name,
        COALESCE(wp.wp_type, 'unknown') AS page_type,
        SUM(ws.ws_ext_sales_price) AS amount,
        COUNT(*) AS txn_cnt,
        'sales' AS activity_type
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_size = 'medium'
      AND w.w_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_count <= 2
      AND i.i_rec_start_date >= DATE '2021-01-01'
    GROUP BY i.i_category, i.i_size, w.w_warehouse_name, ws.ws_sold_date_sk, s.web_name, wp.wp_type
),
returns_agg AS (
    SELECT
        i.i_category,
        i.i_size,
        w.w_warehouse_name,
        cr.cr_returned_date_sk AS date_sk,
        s.web_name,
        'unknown' AS page_type,
        SUM(cr.cr_return_amount) AS amount,
        COUNT(*) AS txn_cnt,
        'returns' AS activity_type
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_site s ON w.w_warehouse_sk = s.web_site_sk  -- using the same join key as sales for illustration (allowed by rule ws_warehouse_sk = w_warehouse_sk, but here we reuse w_warehouse_sk to web_site via ws rule) 
    WHERE i.i_category = 'Electronics'
      AND i.i_size = 'medium'
      AND w.w_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_count <= 2
      AND i.i_rec_start_date >= DATE '2021-01-01'
    GROUP BY i.i_category, i.i_size, w.w_warehouse_name, cr.cr_returned_date_sk, s.web_name
),
combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
)
SELECT
    i_category,
    i_size,
    w_warehouse_name,
    date_sk,
    web_name,
    page_type,
    amount,
    txn_cnt,
    activity_type
FROM combined
ORDER BY i_category, w_warehouse_name, activity_type DESC, amount DESC
