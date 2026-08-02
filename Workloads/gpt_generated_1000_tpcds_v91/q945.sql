WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        d_sales.d_year,
        cc.cc_name,
        sm.sm_ship_mode_id,
        sm.sm_type,
        w.w_warehouse_sk,
        w.w_state,
        ca_bill.ca_state AS bill_state,
        ws.web_site_id
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND ca_bill.ca_state = 'TX'
      AND cs.cs_net_profit > 1000
),
returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        s.s_store_name,
        ca_return.ca_state AS return_state
    FROM store_returns sr
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
    WHERE d_return.d_year = 2001
      AND sr.sr_return_quantity > 1
      AND r.r_reason_desc LIKE '%price%'
),
inventory_q AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk, inv.inv_date_sk
),
order_exclusion AS (
    SELECT cs.cs_order_number AS cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_profit > 500
    EXCEPT
    SELECT sr.sr_ticket_number AS cs_order_number
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
SELECT
    s.cs_order_number,
    s.i_item_id,
    s.i_category,
    s.d_year,
    s.cs_quantity,
    s.cs_ext_sales_price,
    s.cs_net_profit,
    CASE
        WHEN s.cs_net_profit >= 5000 THEN 'High'
        WHEN s.cs_net_profit >= 2000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.cs_net_profit DESC) AS profit_rank,
    iq.total_on_hand AS inventory_on_sale_date,
    r.r_reason_desc
FROM sales s
LEFT JOIN returns r
    ON s.i_item_sk = r.sr_item_sk
   AND s.cs_sold_date_sk = r.sr_returned_date_sk
LEFT JOIN inventory_q iq
    ON s.i_item_sk = iq.inv_item_sk
   AND s.w_warehouse_sk = iq.inv_warehouse_sk
   AND s.cs_sold_date_sk = iq.inv_date_sk
WHERE s.cs_order_number IN (SELECT cs_order_number FROM order_exclusion)
ORDER BY profit_rank, s.cs_net_profit DESC
LIMIT 100
