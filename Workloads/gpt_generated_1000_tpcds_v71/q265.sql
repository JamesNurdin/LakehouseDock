SELECT
    cp.cp_department,
    r.r_reason_desc,
    d_sales.d_year,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(sr.sr_net_loss) AS store_returns_loss,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) AS net_total_profit,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_bill_customers,
    COUNT(DISTINCT ws_site.web_site_id) AS distinct_web_sites
FROM catalog_sales cs
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN customer c_ret
  ON sr.sr_customer_sk = c_ret.c_customer_sk
LEFT JOIN customer_demographics cd_ret
  ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN customer c_web
  ON ws.ws_bill_customer_sk = c_web.c_customer_sk
JOIN customer_demographics cd_web
  ON ws.ws_bill_cdemo_sk = cd_web.cd_demo_sk
GROUP BY
    cp.cp_department,
    r.r_reason_desc,
    d_sales.d_year
HAVING
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) > 10000
ORDER BY
    net_total_profit DESC
LIMIT 100
