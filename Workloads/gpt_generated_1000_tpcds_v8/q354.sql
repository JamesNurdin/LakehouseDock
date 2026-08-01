WITH sales_data AS (
   SELECT
      d.d_year,
      i.i_category,
      ca.ca_state,
      SUM(ss.ss_net_paid_inc_tax) AS total_sales,
      SUM(ss.ss_quantity) AS total_qty,
      ROW_NUMBER() OVER (PARTITION BY d.d_year, i.i_category ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rnk
   FROM store_sales ss
   JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
   JOIN inventory inv             ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_date_sk = d.d_date_sk
   JOIN warehouse w               ON inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc            ON cc.cc_open_date_sk = d.d_date_sk
   JOIN web_site ws               ON ws.web_open_date_sk = d.d_date_sk
   LEFT JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
   LEFT JOIN reason r             ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_year IN (2000, 2001)
     AND cc.cc_tax_percentage > 0.05
     AND ws.web_gmt_offset = -5.00
     AND i.i_category = 'Sports'
     AND ss.ss_net_paid_inc_tax > 1000
     AND inv.inv_quantity_on_hand > 0
   GROUP BY ROLLUP (d.d_year, i.i_category, ca.ca_state)
   HAVING SUM(ss.ss_net_paid_inc_tax) > (
      SELECT AVG(i_current_price)
      FROM item
      WHERE i_category = 'Sports'
   )
)
SELECT d_year, i_category, ca_state, total_sales, total_qty, rnk
FROM sales_data
WHERE rnk = 1

UNION DISTINCT

SELECT d_year, i_category, ca_state, total_sales, total_qty, rnk
FROM sales_data
WHERE rnk = 2

EXCEPT

SELECT d_year, i_category, ca_state, total_sales, total_qty, rnk
FROM sales_data
WHERE i_category = 'Sports' AND ca_state = 'CA'

ORDER BY d_year, i_category, ca_state
LIMIT 100
