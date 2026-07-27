WITH sales_enriched AS (
   SELECT
       ws.ws_order_number,
       ws.ws_net_paid_inc_ship_tax,
       ws.ws_quantity,
       ws.ws_item_sk,
       ws.ws_web_site_sk,
       ws.ws_bill_addr_sk,
       i.i_item_id,
       i.i_manufact,
       i.i_brand,
       i.i_color,
       i.i_current_price,
       regexp_extract(i.i_manufact, '^([a-z]{3})', 1) AS manufact_prefix,
       concat(i.i_brand, ' ', i.i_color) AS brand_color,
       substring(i.i_item_id, 1, 5) AS item_prefix,
       ca.ca_city,
       ca.ca_state,
       wsite.web_name
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE regexp_like(i.i_manufact, '^[a-z]{3}')
     AND wsite.web_suite_number LIKE 'Suite %'
     AND i.i_current_price > 50
     AND i.i_rec_start_date <= DATE '2005-12-31'
)
SELECT
    se.web_name,
    se.manufact_prefix,
    COUNT(DISTINCT se.ws_item_sk) AS distinct_items_sold,
    SUM(se.ws_net_paid_inc_ship_tax) AS total_sales,
    AVG(se.i_current_price) AS avg_item_price,
    ARRAY_AGG(DISTINCT se.ca_city) AS distinct_cities
FROM sales_enriched se
GROUP BY
    se.web_name,
    se.manufact_prefix
HAVING SUM(se.ws_net_paid_inc_ship_tax) > 10000
ORDER BY total_sales DESC
LIMIT 100
