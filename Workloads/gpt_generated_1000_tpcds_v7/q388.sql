WITH sales_data AS (
  SELECT
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_web_site_sk,
    wp.wp_url,
    wp.wp_rec_start_date,
    ca.ca_city,
    ca.ca_state,
    wsit.web_manager
  FROM tpcds.web_sales ws
  JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN tpcds.customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
    AND regexp_like(wp.wp_url, '\\.html$')
    AND ca.ca_city LIKE 'A%'
    AND regexp_like(ca.ca_state, '[A-Z]{2}')
),
processed AS (
  SELECT
    web_manager,
    wp_url,
    ws_net_profit,
    ws_quantity,
    regexp_extract(wp_url, '(https?://[^/]+)') AS domain
  FROM sales_data
)
SELECT
  web_manager,
  domain,
  concat(web_manager, '_', domain) AS manager_domain,
  sum(ws_net_profit) AS total_net_profit,
  count(*) AS sales_cnt,
  avg(ws_quantity) AS avg_quantity
FROM processed
GROUP BY
  web_manager,
  domain,
  concat(web_manager, '_', domain)
HAVING sum(ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10
