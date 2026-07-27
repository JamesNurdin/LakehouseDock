WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
)
SELECT
    cc.cc_name,
    c.c_customer_id,
    i.i_item_id,
    d_sold.d_year,
    ws.ws_net_paid,
    sa.total_net_paid,
    RANK() OVER (ORDER BY sa.total_net_paid DESC) AS sales_rank,
    (
        SELECT COUNT(*)
        FROM web_page wp2
        WHERE wp2.wp_type = wp.wp_type
    ) AS same_type_page_count
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN sales_agg sa ON sa.i_item_sk = i.i_item_sk
WHERE
    cc.cc_state = 'CA'
    AND cd.cd_gender = 'M'
    AND wp.wp_type = 'content'
    AND ws.ws_net_profit > 0
    AND wsit.web_country = 'United States'
ORDER BY sales_rank
LIMIT 100
