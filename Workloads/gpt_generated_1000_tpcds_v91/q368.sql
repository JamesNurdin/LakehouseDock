WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
)
SELECT
    d.d_year,
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    w.w_city,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
    t.street_word,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(cs.cs_quantity) AS min_quantity,
    MAX(cs.cs_quantity) AS max_quantity,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_quantity ELSE 0 END) AS total_return_quantity,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_net_loss
FROM sales cs
INNER JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
INNER JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
INNER JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_date_sk = d.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
CROSS JOIN UNNEST(split(s.s_street_name, ' ')) AS t(street_word)
WHERE d.d_year = 2000
  AND cc.cc_state = 'CA'
  AND i.i_category = 'Books'
  AND s.s_floor_space > 8000000
  AND w.w_city = 'Riverside'
GROUP BY
    d.d_year,
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    w.w_city,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END,
    t.street_word
ORDER BY total_net_paid DESC
LIMIT 100
