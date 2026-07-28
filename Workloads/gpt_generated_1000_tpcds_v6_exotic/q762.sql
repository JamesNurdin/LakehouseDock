WITH all_data AS (
    SELECT
        d.d_year,
        d.d_date_sk,
        i.i_category,
        i.i_item_sk,
        cd.cd_marital_status,
        sm.sm_type,
        SUM(cs.cs_net_paid)               AS total_net_paid,
        SUM(cs.cs_quantity)               AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(ws.ws_net_paid)               AS web_total_net_paid,
        SUM(ir.inv_quantity_on_hand)      AS total_inventory,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
    FROM catalog_sales cs
    JOIN date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i            ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    -- Additional fact tables
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_item_sk = i.i_item_sk
       AND ws.ws_bill_customer_sk = c.c_customer_sk
       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN inventory ir
        ON ir.inv_date_sk = d.d_date_sk
       AND ir.inv_item_sk = i.i_item_sk
       AND ir.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category = 'Sports'
      AND cd.cd_marital_status IN ('M', 'S')
      AND sm.sm_type = 'EXPRESS'
      AND wp.wp_type = 'HOME'
      AND wsit.web_country = 'United States'
    GROUP BY ROLLUP (d.d_year, i.i_category, cd.cd_marital_status, sm.sm_type, i.i_item_sk, d.d_date_sk)
)
SELECT
    sub.d_year,
    sub.i_category,
    sub.cd_marital_status,
    sub.sm_type,
    sub.total_net_paid,
    sub.total_quantity,
    sub.distinct_orders,
    sub.web_total_net_paid,
    sub.total_inventory,
    sub.rn_year
FROM (
    SELECT
        a.d_year,
        a.i_category,
        a.cd_marital_status,
        a.sm_type,
        a.total_net_paid,
        a.total_quantity,
        a.distinct_orders,
        a.web_total_net_paid,
        a.total_inventory,
        ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_paid DESC) AS rn_year
    FROM all_data a
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = a.i_item_sk
          AND sr2.sr_returned_date_sk = a.d_date_sk
    )
) sub
WHERE sub.rn_year = 1
ORDER BY sub.d_year, sub.total_net_paid DESC
LIMIT 100
