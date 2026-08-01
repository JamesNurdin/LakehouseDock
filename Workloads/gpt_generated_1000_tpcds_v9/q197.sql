WITH filtered_inventory AS (
    SELECT inv.inv_item_sk,
           inv.inv_date_sk,
           inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND inv.inv_quantity_on_hand >= 200
)
SELECT i.i_brand,
       i.i_category,
       cp.cp_department,
       ws_site.web_name,
       d_cr.d_year,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
       AVG(ws.ws_sales_price) AS avg_sales_price,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
       COUNT(*) AS row_count
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN filtered_inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d_cr.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                   AND ws.ws_sold_date_sk = d_cr.d_date_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE d_cr.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND cp.cp_department = 'Books'
  AND ws_site.web_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
          AND sr.sr_returned_date_sk = d_cr.d_date_sk
          AND sr.sr_return_amt > 0
    )
GROUP BY i.i_brand,
         i.i_category,
         cp.cp_department,
         ws_site.web_name,
         d_cr.d_year
ORDER BY total_return_amount DESC
LIMIT 100
