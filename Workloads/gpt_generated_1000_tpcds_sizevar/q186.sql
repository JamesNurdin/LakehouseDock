WITH filtered_ship_modes AS (
    SELECT sm_ship_mode_sk
    FROM ship_mode
    WHERE sm_type = 'Air'
)
SELECT
    d.d_year,
    cc.cc_state,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    SUM(ws.ws_net_paid) AS web_total_net_paid,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(cr.cr_return_amount) AS catalog_return_amount
FROM
    catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON d.d_date_sk = inv.inv_date_sk
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN store_returns sr
        ON d.d_date_sk = sr.sr_returned_date_sk
    JOIN web_sales ws
        ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
WHERE
    d.d_year = 2001
    AND cs.cs_sales_price > 30
    AND c.c_preferred_cust_flag = 'Y'
    AND cs.cs_quantity >= 5
    AND cs.cs_call_center_sk IN (SELECT cc_call_center_sk FROM call_center WHERE cc_state = 'TX')
    AND sm.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM filtered_ship_modes)
GROUP BY
    d.d_year,
    cc.cc_state,
    sm.sm_type
ORDER BY
    total_net_paid DESC
LIMIT 100
