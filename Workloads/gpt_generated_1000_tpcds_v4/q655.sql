WITH inv_agg AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           w.w_warehouse_sk,
           w.w_warehouse_name,
           SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk, i.i_product_name, w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cr.cr_return_amount,
    ws.ws_quantity AS web_quantity,
    ss.ss_quantity AS store_quantity,
    i.i_product_name,
    w.w_warehouse_name,
    c.c_customer_id,
    ca.ca_city,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    ws.ws_net_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY cs.cs_net_paid DESC) AS rn_item_sales,
    RANK() OVER (ORDER BY cs.cs_net_paid DESC) AS overall_sales_rank
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_site web
  ON ws.ws_web_site_sk = web.web_site_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN inv_agg inv
  ON inv.i_item_sk = i.i_item_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450816 AND 2450825
  AND i.i_current_price > 100
  AND w.w_state = 'CA'
  AND ca.ca_country = 'United States'
  AND ib.ib_upper_bound >= 50000
  AND td.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_amt > 0
      )
ORDER BY overall_sales_rank
LIMIT 100
