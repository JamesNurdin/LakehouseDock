WITH agg AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    sm.sm_ship_mode_id,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt
  FROM catalog_sales cs
  JOIN date_dim d_sold               ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr           
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk      = cs.cs_item_sk
  JOIN date_dim d_cr_return          ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
  JOIN customer_address ca_bill      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN store_sales ss               
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ss                 ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN store s                       ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca_store_addr ON ss.ss_addr_sk = ca_store_addr.ca_address_sk
  JOIN store_returns sr             
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk        = ss.ss_item_sk
  JOIN date_dim d_sr_ret            ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
  JOIN customer_address ca_sr_addr   ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
  JOIN web_returns wr               
        ON wr.wr_returned_date_sk = d_sr_ret.d_date_sk
  JOIN date_dim d_wr                 ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
  JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
  JOIN inventory inv                 
        ON inv.inv_date_sk = d_sold.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d_inv                ON inv.inv_date_sk = d_inv.d_date_sk
  JOIN web_site ws                   
        ON ws.web_open_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year = 2001
    AND s.s_manager = 'John Mccoy'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
  GROUP BY
    s.s_store_id,
    s.s_store_name,
    sm.sm_ship_mode_id
)
SELECT
  a.s_store_id,
  a.s_store_name,
  a.sm_ship_mode_id,
  a.total_store_net_paid - a.total_store_return_amt AS total_store_net_profit,
  a.total_catalog_net_paid - a.total_catalog_return_amt AS total_catalog_net_profit,
  a.total_web_return_amt,
  ROW_NUMBER() OVER (
    PARTITION BY a.sm_ship_mode_id
    ORDER BY (a.total_store_net_paid - a.total_store_return_amt) DESC
  ) AS store_profit_rank
FROM agg a
EXCEPT
SELECT
  a.s_store_id,
  a.s_store_name,
  a.sm_ship_mode_id,
  a.total_store_net_paid - a.total_store_return_amt,
  a.total_catalog_net_paid - a.total_catalog_return_amt,
  a.total_web_return_amt,
  ROW_NUMBER() OVER (
    PARTITION BY a.sm_ship_mode_id
    ORDER BY (a.total_store_net_paid - a.total_store_return_amt) DESC
  )
FROM agg a
WHERE (a.total_store_net_paid - a.total_store_return_amt) < 0
ORDER BY total_store_net_profit DESC
LIMIT 100
