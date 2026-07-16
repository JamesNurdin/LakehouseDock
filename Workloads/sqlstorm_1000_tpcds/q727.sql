WITH date_range AS (
    SELECT d_date_sk AS date_sk,
           d_date
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 1999
),
sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        'catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales,
        cs.cs_net_profit AS profit,
        cs.cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_page_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT date_sk FROM date_range)
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales,
        ss.ss_net_profit AS profit,
        NULL AS call_center_sk,
        ss.ss_store_sk AS store_sk,
        NULL AS web_page_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT date_sk FROM date_range)
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales,
        ws.ws_net_profit AS profit,
        NULL AS call_center_sk,
        NULL AS store_sk,
        ws.ws_web_page_sk AS web_page_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT date_sk FROM date_range)
),
item_latest_price AS (
    SELECT
        i.i_item_sk,
        i.i_current_price,
        i.i_manager_id,
        i.i_product_name
    FROM item i
    WHERE i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE '2024-10-01'
),
ranked_sales AS (
    SELECT
        s.date_sk,
        d.d_date AS sold_date,
        s.channel,
        s.item_sk,
        i.i_product_name AS product_name,
        s.quantity,
        s.ext_sales,
        s.profit,
        i.i_current_price AS current_price,
        s.call_center_sk,
        s.store_sk,
        s.web_page_sk,
        ROW_NUMBER() OVER (PARTITION BY s.channel, s.date_sk ORDER BY s.ext_sales DESC NULLS LAST) AS sales_rank,
        SUM(s.ext_sales) OVER (PARTITION BY s.channel, s.date_sk) AS channel_daily_total,
        AVG(s.ext_sales) OVER (PARTITION BY s.channel ORDER BY s.date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        CASE
            WHEN s.ext_sales IS NULL OR s.ext_sales = 0 THEN NULL
            ELSE s.profit / NULLIF(s.ext_sales, 0)
        END AS profit_margin,
        CASE
            WHEN i.i_manager_id IS NULL THEN 'UNKNOWN'
            ELSE CONCAT('MGR_', CAST(i.i_manager_id AS VARCHAR))
        END AS manager_code,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM catalog_returns cr
                WHERE cr.cr_item_sk = s.item_sk
                  AND cr.cr_returned_date_sk = s.date_sk
                  AND cr.cr_reason_sk IS NOT NULL
            ) THEN 'RETURNED'
            ELSE 'NO_RETURN'
        END AS return_flag,
        (SELECT COUNT(*) FROM catalog_returns cr
         WHERE cr.cr_item_sk = s.item_sk
           AND cr.cr_returned_date_sk = s.date_sk) AS return_count_today,
        (SELECT MAX(cr.cr_return_amount) FROM catalog_returns cr
         WHERE cr.cr_item_sk = s.item_sk
           AND cr.cr_returned_date_sk = s.date_sk) AS max_return_amount,
        (SELECT SUM(cr.cr_return_quantity) FROM catalog_returns cr
         WHERE cr.cr_item_sk = s.item_sk) AS total_return_quantity,
        (SELECT SUM(cr.cr_return_amount) FROM catalog_returns cr
         WHERE cr.cr_item_sk = s.item_sk) AS total_return_amount
    FROM sales_agg s
    JOIN date_dim d ON d.d_date_sk = s.date_sk
    LEFT JOIN item_latest_price i ON i.i_item_sk = s.item_sk
),
entity_lookup AS (
    SELECT
        cc.cc_call_center_sk AS entity_sk,
        'call_center' AS entity_type,
        cc.cc_name AS entity_name,
        cc.cc_country AS entity_country
    FROM call_center cc
    UNION ALL
    SELECT
        st.s_store_sk AS entity_sk,
        'store' AS entity_type,
        st.s_store_name AS entity_name,
        st.s_country AS entity_country
    FROM store st
    UNION ALL
    SELECT
        wp.wp_web_page_sk AS entity_sk,
        'web_page' AS entity_type,
        wp.wp_url AS entity_name,
        wp.wp_type AS entity_country
    FROM web_page wp
)
SELECT
    rs.date_sk,
    rs.sold_date,
    rs.channel,
    rs.item_sk,
    rs.product_name,
    rs.quantity,
    rs.ext_sales,
    rs.profit,
    rs.current_price,
    rs.sales_rank,
    rs.channel_daily_total,
    rs.moving_avg_7d,
    rs.profit_margin,
    rs.manager_code,
    rs.return_flag,
    rs.return_count_today,
    rs.max_return_amount,
    rs.total_return_quantity,
    rs.total_return_amount,
    COALESCE(lookup.entity_name, 'N/A') AS entity_name,
    COALESCE(lookup.entity_country, 'N/A') AS entity_country,
    CASE
        WHEN rs.manager_code = 'UNKNOWN' THEN NULL
        WHEN reverse(rs.manager_code) = rs.manager_code THEN 'PALINDROME'
        ELSE 'NORMAL'
    END AS manager_code_symmetry,
    CONCAT('#', CAST(rs.item_sk AS VARCHAR), '#') AS item_tag,
    CASE
        WHEN rs.current_price IS NULL OR rs.current_price = 0 THEN NULL
        ELSE rs.ext_sales / rs.current_price
    END AS price_index,
    COALESCE(rs.store_sk, -9999) AS store_sk_coalesced,
    COALESCE(rs.call_center_sk, -9999) AS call_center_sk_coalesced,
    COALESCE(rs.web_page_sk, -9999) AS web_page_sk_coalesced
FROM ranked_sales rs
LEFT JOIN entity_lookup lookup
  ON (lookup.entity_type = 'call_center' AND rs.call_center_sk = lookup.entity_sk)
   OR (lookup.entity_type = 'store'       AND rs.store_sk       = lookup.entity_sk)
   OR (lookup.entity_type = 'web_page'   AND rs.web_page_sk   = lookup.entity_sk)
WHERE rs.sales_rank <= 10
ORDER BY rs.channel, rs.date_sk DESC, rs.sales_rank
