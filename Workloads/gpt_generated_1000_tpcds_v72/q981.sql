WITH sales_data AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_item_sk,
       cs.cs_warehouse_sk,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cs.cs_bill_cdemo_sk,
       cs.cs_bill_hdemo_sk,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       cr.cr_reason_sk,
       wr.wr_return_quantity,
       wr.wr_net_loss,
       wr.wr_reason_sk
   FROM catalog_sales cs
   LEFT JOIN catalog_returns cr
       ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN web_returns wr
       ON wr.wr_item_sk = cs.cs_item_sk
      AND wr.wr_returned_date_sk = cs.cs_sold_date_sk
)

SELECT
    d.d_year,
    s.s_store_name,
    i.i_category,
    SUM(sd.cs_net_paid) AS total_sales,
    SUM(sd.cs_net_profit) AS total_profit,
    SUM(CASE WHEN sd.cr_return_quantity IS NOT NULL THEN sd.cr_net_loss ELSE 0 END) AS catalog_return_loss,
    SUM(CASE WHEN sd.wr_return_quantity IS NOT NULL THEN sd.wr_net_loss ELSE 0 END) AS web_return_loss,
    COUNT(DISTINCT sd.cs_order_number) AS order_cnt,
    SUM(CASE WHEN i.i_color = 'Red' THEN sd.cs_quantity ELSE 0 END) AS red_quantity
FROM sales_data sd
JOIN date_dim d
    ON sd.cs_sold_date_sk = d.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN time_dim t
    ON sd.cs_sold_time_sk = t.t_time_sk
JOIN item i
    ON sd.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON sd.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON sd.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sd.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN reason r_cat
    ON sd.cr_reason_sk = r_cat.r_reason_sk
LEFT JOIN reason r_web
    ON sd.wr_reason_sk = r_web.r_reason_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND ib.ib_upper_bound = 90000
  AND w.w_suite_number = 'Suite 480'
GROUP BY GROUPING SETS (
    (d.d_year, s.s_store_name, i.i_category),
    (d.d_year, s.s_store_name),
    (d.d_year),
    ()
)
HAVING SUM(sd.cs_net_paid) > 100000
ORDER BY total_sales DESC
LIMIT 100
