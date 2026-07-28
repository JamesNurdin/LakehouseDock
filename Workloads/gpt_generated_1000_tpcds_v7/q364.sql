WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_item_sk,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    cc_sales.cc_name AS sales_center_name,
    cp_sales.cp_catalog_page_id AS sales_page_id,
    i_sales.i_brand AS sales_brand,
    td_sold.t_hour AS sale_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) AS total_return_amount_inc_tax,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss
FROM catalog_sales cs
JOIN call_center cc_sales
  ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
JOIN catalog_page cp_sales
  ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
JOIN item i_sales
  ON cs.cs_item_sk = i_sales.i_item_sk
JOIN time_dim td_sold
  ON cs.cs_sold_time_sk = td_sold.t_time_sk
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN call_center cc_return
  ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
LEFT JOIN catalog_page cp_return
  ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
LEFT JOIN item i_return
  ON cr.cr_item_sk = i_return.i_item_sk
LEFT JOIN time_dim td_return
  ON cr.cr_returned_time_sk = td_return.t_time_sk
WHERE cc_sales.cc_rec_start_date >= DATE '2000-01-01'
GROUP BY
    cc_sales.cc_name,
    cp_sales.cp_catalog_page_id,
    i_sales.i_brand,
    td_sold.t_hour
ORDER BY total_sales_amount DESC
