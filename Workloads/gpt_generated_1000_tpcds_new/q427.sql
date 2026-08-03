WITH filtered_web_sales AS (
    SELECT *
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_ext_tax > 20.00
      AND ws_net_profit < 0
)
SELECT
    s.s_store_name,
    d.d_year,
    cp.cp_department,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ws.ws_net_profit) AS avg_web_profit,
    MIN(ws.ws_ext_tax) AS min_web_tax,
    MAX(inv.inv_quantity_on_hand) AS max_inventory_qty
FROM tpcds.catalog_page cp
JOIN tpcds.catalog_returns cr
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store_sales ss
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN filtered_web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.inventory inv
  ON inv.inv_date_sk = d.d_date_sk
WHERE
    s.s_state = 'CA'
    AND cp.cp_type = 'WEB'
    AND d.d_month_seq BETWEEN 1200 AND 1210
    AND hd.hd_buy_potential = 'HIGH'
    AND ss.ss_sales_price > (
        SELECT MAX(ws2.ws_sales_price)
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_quantity > 5
    )
GROUP BY
    s.s_store_name,
    d.d_year,
    cp.cp_department
ORDER BY total_net_paid DESC
LIMIT 100
