WITH date_filtered AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 6 AND 8
),
sales_union AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_store_sk AS dim_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           'store' AS channel
    FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_filtered)
    UNION ALL
    SELECT cs_sold_date_sk AS date_sk,
           cs_call_center_sk AS dim_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_net_paid AS net_paid,
           'catalog' AS channel
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_filtered)
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_web_site_sk AS dim_sk,
           ws_item_sk AS item_sk,
           ws_quantity AS quantity,
           ws_net_paid AS net_paid,
           'web' AS channel
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_filtered)
),
ranked_sales AS (
    SELECT s.*,
           row_number() OVER (PARTITION BY s.dim_sk, s.channel ORDER BY s.net_paid DESC) AS rk
    FROM sales_union s
),
top_sales AS (
    SELECT *
    FROM ranked_sales
    WHERE rk <= 5
)
SELECT
    ts.channel,
    COALESCE(st.s_store_name, cc.cc_name, ws.web_name) AS channel_name,
    ts.item_sk,
    i.i_product_name,
    ts.date_sk,
    d.d_date,
    ts.quantity,
    ts.net_paid,
    CASE
        WHEN ts.net_paid > 10000 THEN 'High'
        WHEN ts.net_paid > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_bucket,
    CONCAT_WS(', ', COALESCE(st.s_city, cc.cc_city, ws.web_city), COALESCE(st.s_state, cc.cc_state, ws.web_state)) AS location,
    (SELECT MAX(s2.net_paid) FROM sales_union s2 WHERE s2.dim_sk = ts.dim_sk AND s2.channel = ts.channel) AS max_channel_net_paid,
    (SELECT COUNT(*) FROM sales_union s3 WHERE s3.item_sk = ts.item_sk) AS total_transactions_for_item,
    CASE WHEN EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_item_sk = ts.item_sk
          AND sr.sr_store_sk = ts.dim_sk
          AND sr.sr_returned_date_sk = ts.date_sk
    ) THEN 'Yes' ELSE 'No' END AS has_return,
    SUM(ts.net_paid) OVER (PARTITION BY ts.channel) AS channel_total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY ts.channel ORDER BY ts.net_paid DESC) AS channel_rank
FROM top_sales ts
LEFT JOIN store st ON ts.channel = 'store' AND ts.dim_sk = st.s_store_sk
LEFT JOIN call_center cc ON ts.channel = 'catalog' AND ts.dim_sk = cc.cc_call_center_sk
LEFT JOIN web_site ws ON ts.channel = 'web' AND ts.dim_sk = ws.web_site_sk
LEFT JOIN item i ON ts.item_sk = i.i_item_sk
LEFT JOIN date_dim d ON ts.date_sk = d.d_date_sk
WHERE ts.rk = 1
ORDER BY ts.channel, ts.net_paid DESC
LIMIT 100
