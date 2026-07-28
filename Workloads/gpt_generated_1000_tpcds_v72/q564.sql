WITH max_inv AS (
    SELECT inv_item_sk, MAX(inv_quantity_on_hand) AS max_qty
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    d.d_year,
    i.i_brand,
    i.i_category,
    cc.cc_name,
    cp.cp_type,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    SUM(CASE WHEN i.i_color = 'Red' THEN cs.cs_ext_sales_price ELSE 0 END) AS red_item_sales,
    max_inv.max_qty,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN max_inv ON max_inv.inv_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#35'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'F'
  AND hd.hd_income_band_sk = 5
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_quantity > 0
    )
GROUP BY
    d.d_year,
    i.i_brand,
    i.i_category,
    cc.cc_name,
    cp.cp_type,
    max_inv.max_qty
ORDER BY total_store_sales DESC
LIMIT 100
