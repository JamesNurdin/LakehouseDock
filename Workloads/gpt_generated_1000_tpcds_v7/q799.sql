WITH
    -- First date dimension for the catalog sale "sold" date
    d_sold AS (
        SELECT * FROM tpcds.date_dim
    ),
    -- Date dimension for the catalog ship date (different alias)
    d_ship AS (
        SELECT * FROM tpcds.date_dim
    ),
    -- Date dimension for store returns "returned" date (re‑used for web returns and web site open date)
    d_return AS (
        SELECT * FROM tpcds.date_dim
    )
SELECT
    s.s_store_name,
    d_sold.d_year,
    SUM(cs.cs_ext_sales_price)      AS total_catalog_sales,
    SUM(ss.ss_net_paid)             AS total_store_sales,
    SUM(sr.sr_net_loss)             AS total_store_returns_loss,
    SUM(wr.wr_net_loss)             AS total_web_returns_loss
FROM tpcds.date_dim d_sold
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN tpcds.date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.store_sales ss
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN tpcds.date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_returns wr
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.time_dim t_return
  ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d_return.d_date_sk
GROUP BY
    s.s_store_name,
    d_sold.d_year
ORDER BY
    s.s_store_name,
    d_sold.d_year
