WITH sales_data AS (
    SELECT
        i.i_item_sk      AS item_sk,
        i.i_item_id      AS item_id,
        d.d_year         AS year,
        cc.cc_state      AS state,
        i.i_brand        AS brand,
        SUM(cs.cs_net_profit)   AS catalog_profit,
        SUM(ws.ws_net_profit)   AS web_profit,
        SUM(cs.cs_net_paid)     AS catalog_sales,
        SUM(ws.ws_net_paid)     AS web_sales,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        SUM(ws.ws_ext_discount_amt) AS web_discount
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
      ON cs.cs_sold_date_sk = d.d_date_sk
     AND cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_item_sk = cs.cs_item_sk
    JOIN tpcds.item i
      ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.warehouse w
      ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.web_site wsit
      ON wsit.web_site_sk = ws.ws_web_site_sk
     AND wsit.web_open_date_sk = d.d_date_sk
    JOIN tpcds.customer c
      ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN tpcds.customer_address ca
      ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN tpcds.household_demographics hd
      ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#23'
      AND ws.ws_ext_discount_amt > 500
      AND w.w_warehouse_sq_ft > 100000
    GROUP BY i.i_item_sk, i.i_item_id, d.d_year, cc.cc_state, i.i_brand
)
SELECT
    sd.item_id,
    sd.year,
    sd.state,
    sd.brand,
    (sd.catalog_profit + sd.web_profit)                         AS total_profit,
    (sd.catalog_sales + sd.web_sales)                           AS total_sales,
    (sd.catalog_profit + sd.web_profit) / NULLIF(sd.catalog_sales + sd.web_sales, 0) AS profit_per_sale,
    (SELECT AVG(inner_tp.total_profit)
       FROM (SELECT (catalog_profit + web_profit) AS total_profit FROM sales_data) inner_tp) AS avg_total_profit_across_items
FROM sales_data sd
WHERE NOT EXISTS (
        SELECT 1 FROM tpcds.catalog_returns cr2 WHERE cr2.cr_item_sk = sd.item_sk
      )
  AND NOT EXISTS (
        SELECT 1 FROM tpcds.store_returns sr2 WHERE sr2.sr_item_sk = sd.item_sk
      )
  AND NOT EXISTS (
        SELECT 1 FROM tpcds.web_returns wr2 WHERE wr2.wr_item_sk = sd.item_sk
      )
ORDER BY total_profit DESC
LIMIT 100
