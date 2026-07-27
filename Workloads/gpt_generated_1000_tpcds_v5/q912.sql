WITH page_sales AS (
   SELECT
       wp.wp_web_page_id,
       wp.wp_url,
       regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
       substring(wp.wp_type FROM 1 FOR 1) AS type_initial,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       p.p_promo_name,
       p.p_discount_active
   FROM tpcds.web_sales ws
   JOIN tpcds.web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN tpcds.customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND wp.wp_url LIKE 'http://www.%'
     AND regexp_like(wp.wp_url, '\\.com$')
     AND substring(wp.wp_type FROM 1 FOR 1) = 'A'
)
SELECT
    concat('Page ', ps.wp_web_page_id) AS page_label,
    ps.domain,
    ps.type_initial,
    sum(ps.ws_ext_sales_price) AS total_sales,
    sum(ps.ws_net_profit) AS total_profit,
    count(*) AS sales_transactions,
    array_agg(DISTINCT ps.p_promo_name) AS promo_names
FROM page_sales ps
WHERE ps.ws_ext_sales_price > (
    SELECT avg(ws_ext_sales_price) FROM tpcds.web_sales
)
GROUP BY
    ps.wp_web_page_id,
    ps.domain,
    ps.type_initial
ORDER BY total_sales DESC
LIMIT 100
