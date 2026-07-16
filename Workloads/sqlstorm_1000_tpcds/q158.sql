WITH all_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_page_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        CAST(NULL AS integer),
        ss.ss_store_sk,
        CAST(NULL AS integer),
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt
    FROM web_sales ws
)
SELECT
    d.d_year,
    i.i_category,
    COALESCE(cc.cc_name, s.s_store_name, wp.wp_url) AS channel_name,
    SUM(all_sales.quantity) AS total_quantity,
    SUM(all_sales.net_paid) AS total_net_paid,
    SUM(all_sales.net_profit) AS total_net_profit,
    AVG(all_sales.discount_amt) AS avg_discount
FROM all_sales
JOIN date_dim d ON all_sales.sold_date_sk = d.d_date_sk
JOIN item i ON all_sales.item_sk = i.i_item_sk
LEFT JOIN call_center cc ON all_sales.call_center_sk = cc.cc_call_center_sk
LEFT JOIN store s ON all_sales.store_sk = s.s_store_sk
LEFT JOIN web_page wp ON all_sales.web_page_sk = wp.wp_web_page_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category, COALESCE(cc.cc_name, s.s_store_name, wp.wp_url)
ORDER BY total_net_paid DESC
LIMIT 100
