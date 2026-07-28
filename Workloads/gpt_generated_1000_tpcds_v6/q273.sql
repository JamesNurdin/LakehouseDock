WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        d.d_year,
        d.d_date,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inv_agg ia ON i.i_item_sk = ia.inv_item_sk
        AND w.w_warehouse_sk = ia.inv_warehouse_sk
    WHERE d.d_year = 2001
      AND we.web_county = 'San Miguel County'
      AND i.i_color = 'Red'
      AND s.s_state = 'CA'
    GROUP BY i.i_item_id, i.i_product_name, w.w_warehouse_name, d.d_year, d.d_date
)
SELECT
    i_item_id,
    i_product_name,
    w_warehouse_name,
    d_year,
    total_sales,
    total_return_amount,
    total_web_sales,
    total_web_return_amount,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY d_date DESC) AS recent_sales_rank
FROM base
ORDER BY total_sales DESC
LIMIT 100
