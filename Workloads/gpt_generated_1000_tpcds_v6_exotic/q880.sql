WITH joined_data AS (
  SELECT
    d.d_date,
    d.d_year,
    s.s_store_name,
    s.s_state,
    we.web_state,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_quantity,
    p.p_discount_active,
    CASE
      WHEN cs.cs_net_profit > 1000 THEN 'High'
      WHEN cs.cs_net_profit BETWEEN 0 AND 1000 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category
  FROM
    date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  WHERE
    d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND we.web_state = 'CA'
    AND cs.cs_quantity > 0
    AND ss.ss_quantity > 0
    AND ws.ws_quantity > 0
    AND EXISTS (
      SELECT 1 FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cs.cs_order_number
        AND cr2.cr_return_amount > 0
    )
)
SELECT
  d_date,
  s_store_name,
  profit_category,
  SUM(cs_net_paid) AS catalog_net_paid,
  SUM(ss_net_paid) AS store_net_paid,
  SUM(ws_net_paid) AS web_net_paid,
  SUM(cs_net_paid + ss_net_paid + ws_net_paid) AS total_net_paid,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_paid + ss_net_paid + ws_net_paid) DESC) AS profit_rank
FROM joined_data
GROUP BY d_date, s_store_name, profit_category, d_year
HAVING SUM(cs_net_paid + ss_net_paid + ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
