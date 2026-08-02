/* Goal: Identify web sites that generated high sales for products whose names start with a two‑letter code followed by three digits, exclude any orders that had a return, extract the product code, and rank sites by sales amount. */
WITH
    sales_filtered AS (
        SELECT
            ws.ws_order_number,
            ws.ws_item_sk,
            ws.ws_web_site_sk,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            ws.ws_ext_sales_price * ws.ws_quantity AS total_sales,
            i.i_product_name,
            wp.wp_url
        FROM web_sales ws
        JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE
            regexp_like(i.i_product_name, '^([A-Z]{2}[0-9]{3}).*')
            AND wp.wp_url LIKE '%/product/%'
            AND regexp_like(wp.wp_url, '/product/[0-9]{5}')
    ),
    returns_filtered AS (
        SELECT
            wr.wr_order_number,
            i.i_product_name,
            wp.wp_url
        FROM web_returns wr
        JOIN item i
            ON wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE
            regexp_like(i.i_product_name, '[a-z]{2}[0-9]{2}$')
            AND wp.wp_url LIKE '%/return/%'
    ),
    sales_orders AS (
        SELECT DISTINCT ws_order_number
        FROM sales_filtered
    ),
    return_orders AS (
        SELECT DISTINCT wr_order_number
        FROM returns_filtered
    ),
    orders_without_returns AS (
        SELECT ws_order_number
        FROM sales_orders
        EXCEPT
        SELECT wr_order_number
        FROM return_orders
    ),
    sales_no_return_details AS (
        SELECT
            sf.ws_order_number,
            sf.ws_item_sk,
            sf.ws_web_site_sk,
            sf.total_sales,
            sf.i_product_name,
            wsite.web_name,
            wsite.web_city
        FROM sales_filtered sf
        JOIN orders_without_returns owr
            ON sf.ws_order_number = owr.ws_order_number
        JOIN web_site wsite
            ON sf.ws_web_site_sk = wsite.web_site_sk
    )
SELECT
    snrd.web_name,
    snrd.web_city,
    COUNT(DISTINCT snrd.ws_order_number) AS orders_cnt,
    SUM(snrd.total_sales) AS total_sales_amount,
    AVG(snrd.total_sales) AS avg_sales_per_order,
    regexp_extract(MIN(snrd.i_product_name), '([A-Z]{2}[0-9]{3})', 1) AS sample_product_code,
    CONCAT(snrd.web_name, ':', snrd.web_city) AS site_label,
    (SELECT AVG(total_sales) FROM sales_no_return_details) AS overall_avg_sales
FROM sales_no_return_details snrd
WHERE snrd.web_name LIKE 'site_%'
  AND snrd.web_city LIKE '%Hill%'
GROUP BY snrd.web_name, snrd.web_city
HAVING SUM(snrd.total_sales) > (SELECT AVG(total_sales) FROM sales_no_return_details)
ORDER BY total_sales_amount DESC
LIMIT 100
