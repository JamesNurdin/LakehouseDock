WITH sampled_sales AS (
    SELECT *
    FROM tpcds.web_sales TABLESAMPLE BERNOULLI (5)
    WHERE ws_ext_discount_amt > (
        SELECT avg(ws_ext_discount_amt)
        FROM tpcds.web_sales
        WHERE ws_warehouse_sk = 1
    )
)
SELECT
    s.s_store_name,
    i.i_item_id,
    d_sold.d_year,
    seq_tbl.seq,
    tax_array_elem,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(ws.ws_net_profit) -
        SUM(cr.cr_net_loss) -
        SUM(sr.sr_net_loss) -
        SUM(wr.wr_net_loss) AS net_margin
FROM sampled_sales ws
JOIN tpcds.date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site webs
  ON ws.ws_web_site_sk = webs.web_site_sk
JOIN tpcds.web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
   AND wr.wr_item_sk = i.i_item_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN tpcds.reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_refunded_customer_sk = c_bill.c_customer_sk
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_customer_sk = c_bill.c_customer_sk
JOIN tpcds.store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN tpcds.date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN tpcds.customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN tpcds.household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN (SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3) AS seq_tbl
JOIN (
    SELECT ws_order_number,
           ARRAY[ws_net_paid * 0.05, ws_net_paid * 0.10] AS tax_array
    FROM sampled_sales
) tax_cte
  ON ws.ws_order_number = tax_cte.ws_order_number
CROSS JOIN UNNEST(tax_cte.tax_array) AS t(tax_array_elem)
GROUP BY
    s.s_store_name,
    i.i_item_id,
    d_sold.d_year,
    seq_tbl.seq,
    tax_array_elem
ORDER BY net_margin DESC
OFFSET 10 ROWS
LIMIT 100
