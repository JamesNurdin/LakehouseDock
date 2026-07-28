WITH sales_agg AS (
    SELECT
        d.d_year AS d_year,
        i.i_item_id AS i_item_id,
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND i.i_brand = 'Brand#23'
      AND we.web_country = 'United States'
    GROUP BY d.d_year, i.i_item_id, i.i_brand, i.i_category
)
SELECT
    d_year,
    i_item_id,
    i_brand,
    i_category,
    total_sales,
    catalog_net_profit,
    web_net_profit,
    total_inventory,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM sales_agg
ORDER BY d_year, sales_rank
LIMIT 100
