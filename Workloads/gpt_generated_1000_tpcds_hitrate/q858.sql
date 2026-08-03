WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d.d_year,
    i_cs.i_category,
    ws.web_country,
    CASE WHEN i_cs.i_color = 'red' THEN 'Red' ELSE 'Other' END AS color_category,
    SUM(cs.cs_ext_sales_price)               AS total_catalog_sales,
    SUM(ss.ss_net_paid)                      AS total_store_sales,
    inv_agg.total_qty,
    avg_item_sales.avg_sales_price,
    COUNT(DISTINCT CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_order_number END) AS return_orders,
    SUM(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_discount_amt ELSE 0 END) AS total_discount
FROM catalog_sales cs
-- date and time for the catalog sale
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
-- item sold in the catalog sale
JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
-- promotion linked to the catalog sale
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
-- billing customer information
LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
-- billing and shipping addresses (same table used twice)
LEFT JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
-- warehouse for the catalog shipment
LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
-- pre‑aggregated inventory for the same item/warehouse
LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i_cs.i_item_sk
                AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
-- store sales brought in through a FULL OUTER JOIN (keeps unmatched rows)
FULL OUTER JOIN (
    SELECT
        ss.*, 
        d2.d_year   AS ss_year,
        t2.t_hour   AS ss_hour,
        i_ss.i_category,
        i_ss.i_color,
        ca_ss.ca_address_sk
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
    JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
    LEFT JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
    LEFT JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
) ss ON ss.ss_sold_date_sk = d.d_date_sk
-- web returns linked to the same item and date
LEFT JOIN web_returns wr ON wr.wr_item_sk = i_cs.i_item_sk
                        AND wr.wr_returned_date_sk = d.d_date_sk
-- web page that recorded the return
LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
-- sampled web site information
LEFT JOIN (
    SELECT *
    FROM web_site TABLESAMPLE BERNOULLI (10)
) ws ON ws.web_open_date_sk = d.d_date_sk
-- lateral subquery: average catalog sales price for the item
LEFT JOIN LATERAL (
    SELECT AVG(cs2.cs_ext_sales_price) AS avg_sales_price
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = i_cs.i_item_sk
) avg_item_sales ON TRUE
WHERE cs.cs_net_paid > (
        SELECT MAX(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = cs.cs_sold_date_sk
    )
  AND EXISTS (
        SELECT 1
        FROM promotion p3
        WHERE p3.p_promo_sk = cs.cs_promo_sk
          AND p3.p_discount_active = 'Y'
    )
GROUP BY
    d.d_year,
    i_cs.i_category,
    ws.web_country,
    i_cs.i_color,
    inv_agg.total_qty,
    avg_item_sales.avg_sales_price
ORDER BY total_catalog_sales DESC
LIMIT 100
