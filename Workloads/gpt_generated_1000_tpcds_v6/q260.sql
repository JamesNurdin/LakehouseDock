WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_item_sk,
       ss.ss_customer_sk,
       ss.ss_hdemo_sk,
       ss.ss_addr_sk,
       ss.ss_ticket_number,
       ss.ss_quantity,
       ss.ss_sales_price,
       ss.ss_net_paid,
       ss.ss_net_profit,
       ss.ss_ext_sales_price,
       ss.ss_ext_discount_amt,
       ss.ss_ext_tax,
       d.d_year,
       t.t_shift,
       i.i_brand,
       i.i_category,
       c.c_customer_id,
       ca.ca_city,
       hd.hd_income_band_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND t.t_shift = 'first'
     AND i.i_brand = 'Brand#12'
),
joined AS (
   SELECT
       b.*,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_net_loss AS store_return_loss,
       inv.inv_quantity_on_hand,
       wp.wp_url,
       wp.wp_link_count,
       wr.wr_refunded_cash,
       wr.wr_net_loss AS web_return_loss
   FROM base b
   LEFT JOIN store_returns sr
       ON sr.sr_ticket_number = b.ss_ticket_number
      AND sr.sr_item_sk = b.ss_item_sk
   LEFT JOIN inventory inv
       ON inv.inv_item_sk = b.ss_item_sk
      AND inv.inv_date_sk = b.ss_sold_date_sk
   LEFT JOIN web_page wp
       ON wp.wp_creation_date_sk = b.ss_sold_date_sk
   LEFT JOIN web_returns wr
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
      AND wr.wr_item_sk = b.ss_item_sk
),
agg AS (
   SELECT
       j.c_customer_id,
       j.d_year,
       j.i_category,
       SUM(j.ss_ext_sales_price) AS total_sales,
       SUM(j.ss_net_profit) AS total_profit,
       COUNT(DISTINCT j.ss_ticket_number) AS distinct_transactions,
       AVG(j.ss_quantity) AS avg_quantity,
       SUM(COALESCE(j.sr_return_quantity, 0)) AS total_return_qty,
       SUM(COALESCE(j.wr_refunded_cash, 0)) AS total_refunded_cash
   FROM joined j
   GROUP BY j.c_customer_id, j.d_year, j.i_category
   HAVING SUM(j.ss_ext_sales_price) > 10000
)
SELECT
   a.*, 
   ROW_NUMBER() OVER (PARTITION BY a.c_customer_id ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 100
