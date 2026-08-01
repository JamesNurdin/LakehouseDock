WITH sales_summary AS (
  SELECT
    d.d_year AS sales_year,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    MAX(ss.ss_net_profit) AS max_net_profit,
    MIN(sr.sr_net_loss) AS min_return_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_visited
  FROM
    date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_returned_date_sk = d.d_date_sk
      AND sr.sr_item_sk = i.i_item_sk
      AND sr.sr_customer_sk = c.c_customer_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
      AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
      AND wp.wp_customer_sk = c.c_customer_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE
    c.c_first_name = 'Karen'
    AND d.d_quarter_seq = 1
    AND i.i_color = 'Red'
    AND ss.ss_ext_list_price > 1000
    AND inv.inv_quantity_on_hand >= 100
    AND w.w_city = 'New York'
    AND NOT EXISTS (
      SELECT 1 FROM store_returns sr2
      WHERE sr2.sr_customer_sk = c.c_customer_sk
        AND sr2.sr_return_amt > 200
    )
  GROUP BY
    d.d_year,
    cd.cd_gender,
    cd.cd_marital_status
)
SELECT *
FROM sales_summary
ORDER BY total_net_paid DESC
LIMIT 100
