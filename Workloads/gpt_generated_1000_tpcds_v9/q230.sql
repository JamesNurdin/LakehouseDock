SELECT
    w.w_warehouse_name,
    wsite.web_name,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    concat(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1), '-', wsite.web_name) AS domain_site,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    SUBSTRING(cc.cc_manager, 1, 5) AS manager_prefix,
    (SELECT AVG(ws_sub.ws_ext_sales_price)
       FROM web_sales ws_sub
      WHERE ws_sub.ws_warehouse_sk = w.w_warehouse_sk) AS avg_warehouse_sales,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > (SELECT AVG(ws_sub.ws_ext_sales_price)
                                            FROM web_sales ws_sub
                                           WHERE ws_sub.ws_warehouse_sk = w.w_warehouse_sk)
        THEN 'AboveAvg' ELSE 'BelowAvg' END AS sales_vs_avg
FROM
    web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE
    d_sold.d_date BETWEEN DATE '2020-01-01' AND DATE '2021-12-31'
    AND wp.wp_url IS NOT NULL
    AND regexp_like(wp.wp_url, '^https?://.*example\\.com')
    AND wsite.web_name LIKE '%Shop%'
    AND cc.cc_name IS NOT NULL
    AND regexp_like(cc.cc_name, '^A.*')
GROUP BY
    w.w_warehouse_name,
    w.w_warehouse_sk,
    wsite.web_name,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1),
    concat(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1), '-', wsite.web_name),
    SUBSTRING(cc.cc_manager, 1, 5)
ORDER BY
    total_net_profit DESC
LIMIT 100
