WITH sales_per_customer AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk
)
SELECT
    c.c_customer_id,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    hd.hd_buy_potential,
    cp.cp_department,
    SUM(spc.total_net_profit) AS sum_net_profit,
    SUM(spc.total_quantity) AS sum_quantity,
    AVG(ws.ws_sales_price) AS avg_ws_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS ws_orders,
    MAX(r.r_reason_desc) FILTER (WHERE r.r_reason_desc IS NOT NULL) AS sample_return_reason,
    ws_site.web_name,
    t.t_hour
FROM sales_per_customer spc
JOIN date_dim d
  ON spc.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON spc.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    c.c_birth_country IN ('URUGUAY', 'FIJI')
    AND d.d_year = 2001
    AND ws.ws_ext_wholesale_cost > 2000
    AND cp.cp_department = 'Books'
    AND hd.hd_income_band_sk > 5
    AND ws_site.web_gmt_offset = -5.00
    AND spc.total_net_profit > (SELECT AVG(ss_net_profit) FROM store_sales)
GROUP BY
    c.c_customer_id,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    hd.hd_buy_potential,
    cp.cp_department,
    ws_site.web_name,
    t.t_hour
HAVING
    SUM(spc.total_net_profit) > 1000
ORDER BY
    sum_net_profit DESC,
    c.c_customer_id
LIMIT 100
