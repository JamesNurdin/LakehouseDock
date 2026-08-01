WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    s.s_store_name,
    d.d_year,
    sm.sm_type,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_returns_amount,
    SUM(i_agg.total_quantity_on_hand) AS total_inventory_on_hand
FROM date_dim d
    INNER JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory_agg i_agg
        ON i_agg.inv_warehouse_sk = w.w_warehouse_sk
        AND i_agg.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE
    d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND s.s_state = 'CA'
    AND sm.sm_carrier = 'UPS'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_net_paid > 1000
          AND ws2.ws_sold_date_sk = d.d_date_sk
    )
GROUP BY ROLLUP (s.s_store_name, d.d_year, sm.sm_type)
