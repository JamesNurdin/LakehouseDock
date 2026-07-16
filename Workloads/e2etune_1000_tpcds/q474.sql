WITH sales AS (
    SELECT i.i_brand AS brand,
           ca.ca_state AS state,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_brand, ca.ca_state
),
returns AS (
    SELECT i.i_brand AS brand,
           ca.ca_state AS state,
           SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_brand, ca.ca_state
),
inventory_agg AS (
    SELECT i.i_brand AS brand,
           AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_brand
)
SELECT s.brand,
       s.state,
       s.total_sales,
       COALESCE(r.total_returns, 0) AS total_returns,
       (s.total_sales - COALESCE(r.total_returns, 0)) AS net_revenue,
       s.total_profit,
       i.avg_inventory_qty,
       CASE WHEN s.total_sales > 0 THEN (s.total_profit - COALESCE(r.total_returns, 0)) / s.total_sales ELSE NULL END AS profit_margin
FROM sales s
LEFT JOIN returns r
    ON s.brand = r.brand AND s.state = r.state
LEFT JOIN inventory_agg i
    ON s.brand = i.brand
WHERE s.total_sales > 10000
  AND i.avg_inventory_qty > 0
ORDER BY net_revenue DESC
LIMIT 20
