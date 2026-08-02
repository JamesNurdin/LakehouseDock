WITH ss_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS sum_ss_net_paid,
        SUM(ss_net_profit) AS sum_ss_net_profit,
        COUNT(*) AS cnt_ss_orders
    FROM store_sales
    WHERE ss_quantity > 5
    GROUP BY ss_sold_date_sk, ss_item_sk
)
SELECT
    d.d_date,
    cc.cc_name,
    cp.cp_description,
    ca.ca_city,
    hd.hd_buy_potential,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(ss_agg.sum_ss_net_paid) AS total_store_net_paid,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    AVG(cs.cs_sales_price) AS avg_catalog_sales_price,
    MIN(ss.ss_quantity) AS min_store_quantity,
    MAX(sr.sr_return_quantity) AS max_store_return_quantity
FROM
    inventory inv
    FULL OUTER JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN ss_agg
        ON ss_agg.ss_sold_date_sk = ss.ss_sold_date_sk
        AND ss_agg.ss_item_sk = ss.ss_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
WHERE
    d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND w.w_city = 'San Francisco'
    AND cp.cp_type = 'Electronic'
    AND ca.ca_state = 'CA'
    AND inv.inv_quantity_on_hand > 100
    AND cs.cs_net_paid > 500
GROUP BY
    d.d_date,
    cc.cc_name,
    cp.cp_description,
    ca.ca_city,
    hd.hd_buy_potential
ORDER BY
    d.d_date DESC,
    total_store_net_paid DESC
LIMIT 100
