WITH high_spenders AS (
    SELECT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ss.ss_net_paid) > 5000
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    d.d_year,
    d.d_quarter_name,
    SUM(cs.cs_net_profit)               AS total_net_profit,
    AVG(cs.cs_sales_price)               AS avg_sales_price,
    COUNT(DISTINCT cs.cs_order_number)   AS distinct_orders,
    COUNT(*)                              AS rows_processed
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN web_site ws
  ON wp.wp_creation_date_sk = ws.web_open_date_sk
WHERE
    d.d_year = 2020
    AND d.d_quarter_name = 'Q1'
    AND i.i_brand = 'Brand#23'
    AND cp.cp_type = 'monthly'
    AND ws.web_country = 'United States'
    AND c.c_customer_sk IN (SELECT c_customer_sk FROM high_spenders)
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    d.d_year,
    d.d_quarter_name
ORDER BY total_net_profit DESC
LIMIT 20
