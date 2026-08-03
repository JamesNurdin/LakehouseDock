WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
      AND ws.ws_ext_discount_amt < 100
      AND ws.ws_ship_mode_sk IN (5, 13, 16)
    GROUP BY ws.ws_web_site_sk, ws.ws_bill_cdemo_sk, ws.ws_item_sk
    HAVING SUM(ws.ws_ext_sales_price) > 500
)
SELECT
    ws_agg.ws_web_site_sk,
    ws_agg.total_sales,
    ws_agg.total_qty,
    cd.cd_gender,
    cd.cd_education_status,
    i.i_brand,
    i.i_category,
    ws_agg.avg_sales_price,
    ROW_NUMBER() OVER (
        PARTITION BY ws_agg.ws_web_site_sk
        ORDER BY ws_agg.total_sales DESC
    ) AS sales_rank,
    CASE
        WHEN ws_agg.total_sales > 1000 THEN 'High'
        WHEN ws_agg.total_sales > 500 THEN 'Medium'
        ELSE 'Low'
    END AS sales_bucket,
    ws_agg.order_cnt,
    ws.web_state,
    ws.web_mkt_id
FROM sales_agg ws_agg
RIGHT OUTER JOIN web_site ws
    ON ws.web_site_sk = ws_agg.ws_web_site_sk
JOIN customer_demographics cd
    ON ws_agg.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN item i
    ON ws_agg.ws_item_sk = i.i_item_sk
WHERE ws.web_state = 'CA'
  AND ws.web_mkt_id = 4
  AND i.i_current_price BETWEEN 10 AND 100
  AND cd.cd_dep_count <= 2
  AND cd.cd_credit_rating = 'C'
ORDER BY ws_agg.total_sales DESC
LIMIT 100
