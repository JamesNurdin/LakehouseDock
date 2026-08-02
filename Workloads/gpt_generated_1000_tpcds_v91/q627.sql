WITH sales_per_item AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_brand_id,
        i.i_item_desc,
        i.i_product_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        MAX(regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1)) AS domain
    FROM
        web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_item_desc LIKE '%Special%'
        AND regexp_like(wp.wp_url, '^https?://[^/]+/.*$')
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_brand_id,
        i.i_item_desc,
        i.i_product_name
)
SELECT
    s.i_brand,
    s.i_brand_id,
    s.i_item_id,
    s.i_product_name,
    CONCAT(s.i_brand, ' - ', s.i_item_desc) AS brand_item_desc,
    SUBSTRING(s.i_item_desc, 1, 30) AS short_desc,
    s.total_net_paid,
    s.total_discount,
    s.distinct_customers,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_item_sk = s.i_item_sk) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY s.i_brand ORDER BY s.total_net_paid DESC) AS brand_item_rank,
    s.domain
FROM
    sales_per_item s
ORDER BY
    s.total_net_paid DESC
LIMIT 100
