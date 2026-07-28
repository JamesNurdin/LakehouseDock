WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cc.cc_name,
        cp.cp_catalog_page_number,
        i.i_item_id,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_refunded_cash,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_refunded_cash,
        ca.ca_state,
        ca.ca_city,
        cd.cd_gender,
        td.t_hour
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
        AND i.i_current_price > 1000
        AND cs.cs_quantity > 5
        AND cs.cs_ext_tax < 50
        AND cc.cc_gmt_offset BETWEEN -5 AND 5
        AND ca.ca_state = 'CA'
),
customer_agg AS (
    SELECT
        c_customer_sk,
        SUM(cs_net_paid + ws_net_paid - COALESCE(cr_refunded_cash, 0) - COALESCE(wr_refunded_cash, 0)) AS total_net_paid
    FROM joined_data
    GROUP BY c_customer_sk
)
SELECT
    AVG(total_net_paid) AS avg_customer_total_net_paid,
    COUNT(*) AS customer_count
FROM customer_agg
WHERE total_net_paid > 5000
ORDER BY avg_customer_total_net_paid DESC
LIMIT 100
