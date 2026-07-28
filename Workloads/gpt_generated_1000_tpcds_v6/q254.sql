WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
)
SELECT
    d_sold.d_year,
    i.i_item_id,
    i.i_category,
    w.w_warehouse_name,
    cp.cp_department,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
    AVG(cs.cs_net_paid) OVER (PARTITION BY i.i_item_id) AS avg_item_sales,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cs.cs_net_paid DESC) AS sales_rank,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
    ) AS total_returns,
    r.r_reason_desc
FROM sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
 AND inv.inv_date_sk = d_sold.d_date_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_ret
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_category = 'Electronics'
  AND w.w_state = 'CA'
ORDER BY cs.cs_net_paid DESC
LIMIT 100
