WITH store_part AS (
    SELECT
        i.i_item_id,
        st.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS trans_cnt,
        'store' AS channel
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store st ON ss.ss_store_sk = st.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, st.s_store_name
),
web_part AS (
    SELECT
        i.i_item_id,
        NULL AS s_store_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS trans_cnt,
        'web' AS channel
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id
)
SELECT
    i_item_id,
    s_store_name,
    total_sales,
    trans_cnt,
    channel
FROM (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM web_part
) AS combined
ORDER BY total_sales DESC
LIMIT 100
