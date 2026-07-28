WITH joined_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        inv.inv_quantity_on_hand,
        ca_bill.ca_state,
        p.p_discount_active,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 5
),
aggregated AS (
    SELECT
        i_item_id,
        i_product_name,
        d_year,
        d_month_seq,
        SUM(cs_net_profit + ss_net_profit + ws_net_profit) AS total_net_profit,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT ca_state) AS distinct_customer_states
    FROM joined_data
    GROUP BY i_item_id, i_product_name, d_year, d_month_seq
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.d_year,
    a.d_month_seq,
    a.total_net_profit,
    a.total_quantity_on_hand,
    a.distinct_customer_states,
    DENSE_RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.total_net_profit DESC, profit_rank
LIMIT 100
