WITH
    agg_sales AS (
        SELECT
            cs_item_sk,
            cs_bill_customer_sk,
            cs_order_number,
            COUNT(*) AS sales_cnt,
            SUM(cs_net_paid) AS total_net_paid
        FROM catalog_sales
        WHERE cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_color = 'Red')
        GROUP BY cs_item_sk, cs_bill_customer_sk, cs_order_number
    ),
    inv_agg AS (
        SELECT
            inv_item_sk,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    ),
    cust_exclusive AS (
        SELECT ws_bill_customer_sk AS cust_sk FROM web_sales
        EXCEPT
        SELECT ss_customer_sk FROM store_sales
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    i2.i_brand,
    agg.sales_cnt,
    agg.total_net_paid,
    inv.total_on_hand,
    c.c_customer_id,
    cd.cd_gender,
    ca.ca_city,
    p.p_promo_name,
    p2.p_promo_name AS ws_promo_name,
    s.s_store_name,
    wp.wp_url,
    r.r_reason_desc,
    CASE WHEN agg.total_net_paid > 10000 THEN 'High' ELSE 'Low' END AS revenue_category,
    dates.report_date
FROM agg_sales agg
JOIN item i ON agg.cs_item_sk = i.i_item_sk
JOIN inv_agg inv ON i.i_item_sk = inv.inv_item_sk
JOIN customer c ON agg.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
FULL OUTER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
CROSS JOIN (
    SELECT DATE '2023-01-01' AS report_date UNION ALL SELECT DATE '2023-01-02'
) dates
WHERE c.c_customer_sk IN (SELECT cust_sk FROM cust_exclusive)
ORDER BY agg.total_net_paid DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
