WITH cs_agg AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_order_number,
       cs.cs_catalog_page_sk,
       cs.cs_sold_date_sk,
       cs.cs_bill_customer_sk,
       cs.cs_bill_cdemo_sk,
       cs.cs_bill_hdemo_sk,
       cs.cs_bill_addr_sk,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_quantity)        AS total_qty
   FROM catalog_sales cs
   GROUP BY cs.cs_item_sk,
            cs.cs_order_number,
            cs.cs_catalog_page_sk,
            cs.cs_sold_date_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk
)
SELECT
    cp.cp_department,
    d_sales.d_year,
    COUNT(DISTINCT c.c_customer_sk)                     AS unique_customers,
    SUM(cs_agg.total_sales)                             AS sum_sales,
    SUM(cr.cr_return_amount)                           AS sum_return_amount,
    SUM(ws.ws_ext_sales_price)                         AS sum_web_sales,
    SUM(wr.wr_return_amt)                              AS sum_web_return_amt,
    CASE WHEN SUM(cs_agg.total_sales) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM cs_agg
JOIN catalog_page cp           ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sales           ON cs_agg.cs_sold_date_sk   = d_sales.d_date_sk
JOIN customer c                ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd  ON cs_agg.cs_bill_cdemo_sk   = cd.cd_demo_sk
JOIN household_demographics hd ON cs_agg.cs_bill_hdemo_sk   = hd.hd_demo_sk
JOIN customer_address ca_addr  ON cs_agg.cs_bill_addr_sk    = ca_addr.ca_address_sk
LEFT JOIN catalog_returns cr   ON cr.cr_order_number = cs_agg.cs_order_number
                                 AND cr.cr_item_sk   = cs_agg.cs_item_sk
LEFT JOIN web_sales ws        ON ws.ws_order_number = cs_agg.cs_order_number
                                 AND ws.ws_item_sk    = cs_agg.cs_item_sk
LEFT JOIN web_returns wr      ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk    = ws.ws_item_sk
JOIN inventory inv            ON inv.inv_quantity_on_hand > 0
JOIN date_dim d_inv            ON inv.inv_date_sk = d_inv.d_date_sk
WHERE d_sales.d_year = 2001
  AND cp.cp_department = 'Books'
  AND c.c_birth_month = 5
  AND cs_agg.cs_item_sk IN (
        SELECT inv2.inv_item_sk
        FROM inventory inv2
        WHERE inv2.inv_quantity_on_hand > 1000
      )
GROUP BY cp.cp_department, d_sales.d_year
LIMIT 100
