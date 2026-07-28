WITH cs AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_item_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_bill_customer_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        cs_net_paid,
        cs_order_number
    FROM catalog_sales
    WHERE cs_net_paid > 100
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    i.i_product_name,
    d.d_date,
    cs.cs_net_paid,
    cr.cr_return_amount,
    inv.inv_quantity_on_hand,
    (
        SELECT MAX(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
    ) AS max_qty_for_item,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_net_paid DESC) AS rn_per_customer,
    RANK() OVER (ORDER BY cs.cs_net_paid DESC) AS overall_rank
FROM cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
     AND i.i_brand = 'BrandX'
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
     AND r.r_reason_id = 'AAAAAAAAMAAAAAAA'
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND inv.inv_quantity_on_hand > 500
  AND ws.web_country = 'United States'
ORDER BY overall_rank ASC
LIMIT 100
