WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    d_sold.d_year AS sales_year,
    d_return.d_year AS return_year,
    ws.web_name,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    inv_agg.total_qty_on_hand
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
  ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_return
  ON sr.sr_returned_date_sk = d_store_return.d_date_sk
JOIN time_dim t_store_return
  ON sr.sr_return_time_sk = t_store_return.t_time_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN inv_agg
  ON inv_agg.inv_item_sk = i.i_item_sk
  AND inv_agg.inv_date_sk = d_sold.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs.cs_order_number
      AND cr2.cr_return_amount > 500
    GROUP BY cr2.cr_order_number
    HAVING COUNT(DISTINCT cr2.cr_returned_date_sk) > 0
)
GROUP BY
    c.c_customer_id,
    i.i_item_id,
    d_sold.d_year,
    d_return.d_year,
    ws.web_name,
    inv_agg.total_qty_on_hand
ORDER BY total_sales DESC
LIMIT 100
