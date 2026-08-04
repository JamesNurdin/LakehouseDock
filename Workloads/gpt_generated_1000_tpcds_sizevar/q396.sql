WITH base AS (
    SELECT
        c.c_customer_sk,
        d.d_year,
        cs.cs_net_paid AS cs_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        sr.sr_return_amt AS sr_return_amt,
        inv.inv_quantity_on_hand AS inv_qty,
        w.w_warehouse_name,
        i.i_item_id,
        sm.sm_type,
        ws.ws_web_site_sk,
        ws.ws_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        AND we.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND w.w_state = 'CA'
      AND cs.cs_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red')
)
SELECT
    c_customer_sk,
    d_year,
    SUM(cs_net_paid) AS total_cs_paid,
    SUM(ws_net_paid) AS total_ws_paid,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(inv_qty) AS total_inventory_on_hand,
    SUM(cs_net_paid + ws_net_paid - COALESCE(sr_return_amt, 0)) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_paid + ws_net_paid - COALESCE(sr_return_amt, 0)) DESC) AS sales_rank
FROM base
GROUP BY ROLLUP (c_customer_sk, d_year)
ORDER BY d_year, net_sales DESC
LIMIT 100
