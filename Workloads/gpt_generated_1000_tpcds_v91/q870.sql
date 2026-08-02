SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_number,
    r.r_reason_desc,
    sm.sm_carrier,
    sm.sm_contract,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_net_profit,
    ws_site.web_name,
    RANK() OVER (PARTITION BY ws_site.web_name ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    (SELECT SUM(cr2.cr_return_amount)
       FROM catalog_returns cr2
      WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk) AS total_refunded_amount_by_customer
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE cp.cp_department = 'Sports'
  AND sm.sm_carrier = 'UPS'
  AND r.r_reason_id IN ('AAAAAAAABBAAAAAA', 'AAAAAAAAPAAAAAAA')
  AND c.c_birth_year BETWEEN 1965 AND 1975
  AND ws.ws_sold_date_sk BETWEEN 2451277 AND 2452550
  AND EXISTS (SELECT 1
                FROM web_returns wr
               WHERE wr.wr_order_number = ws.ws_order_number
                 AND wr.wr_refunded_customer_sk = c.c_customer_sk
                 AND wr.wr_reason_sk = r.r_reason_sk)
ORDER BY profit_rank ASC, ws.ws_net_profit DESC
LIMIT 100
