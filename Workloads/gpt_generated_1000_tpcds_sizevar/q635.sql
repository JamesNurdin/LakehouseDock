WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 5
)
SELECT
    d.d_year,
    cp.cp_department,
    i.i_brand,
    i.i_product_name,
    cd.cd_gender,
    cs.cs_net_paid,
    ws.ws_net_paid,
    r.r_reason_desc,
    s.s_store_name,
    wp.wp_url,
    wsite.web_name,
    (cs.cs_sales_price - (SELECT MAX(i_current_price) FROM item)) AS price_diff,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY cs.cs_net_paid DESC) AS brand_sales_rank
FROM cs_sample cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
FULL OUTER JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'BrandX'
  AND cp.cp_department = 'Shoes'
  AND cd.cd_purchase_estimate BETWEEN 2000 AND 5000
  AND s.s_state = 'CA'
  AND wp.wp_type = 'Home'
ORDER BY brand_sales_rank, d.d_year
LIMIT 100
