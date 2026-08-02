WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
),
returns_agg AS (
    SELECT
        wr_order_number,
        COUNT(*) AS return_cnt
    FROM web_returns
    GROUP BY wr_order_number
)
SELECT
    cs.cs_order_number,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    cc.cc_name,
    ws.web_name,
    s.s_store_name,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    CASE WHEN cs.cs_ext_tax > 10 THEN 'High' ELSE 'Low' END AS tax_category,
    ia.total_qty,
    lr.return_cnt
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN inv_agg ia
    ON ia.inv_date_sk = d_sold.d_date_sk
    AND ia.inv_item_sk = cs.cs_item_sk
CROSS JOIN LATERAL (
    SELECT COALESCE(r.return_cnt, 0) AS return_cnt
    FROM returns_agg r
    WHERE r.wr_order_number = cs.cs_order_number
) lr
WHERE cs.cs_order_number NOT IN (SELECT wr_order_number FROM web_returns)
  AND d_sold.d_year = 1911
ORDER BY cs.cs_order_number
LIMIT 100
