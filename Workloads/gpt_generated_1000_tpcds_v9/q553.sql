WITH sales_base AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        c.c_customer_id,
        ca.ca_city,
        cc.cc_state,
        cd.cd_credit_rating,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS sum_cs_net_paid,
        SUM(ws.ws_net_paid) AS sum_ws_net_paid,
        SUM(cs.cs_net_profit) AS sum_cs_net_profit,
        SUM(ws.ws_net_profit) AS sum_ws_net_profit,
        SUM(sr.sr_return_amt) AS sum_store_return_amt,
        SUM(wr.wr_return_amt) AS sum_web_return_amt,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_qty
    FROM catalog_sales cs
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND ca.ca_county = 'Madison County'
      AND cc.cc_state = 'CA'
      AND i.i_category = 'Electronics'
      AND t_cs.t_hour BETWEEN 9 AND 17
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        c.c_customer_id,
        ca.ca_city,
        cc.cc_state,
        cd.cd_credit_rating,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        p.p_promo_name
    HAVING (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)) > 2000
)
SELECT
    sb.i_item_id,
    sb.i_item_desc,
    sb.i_category,
    sb.i_brand,
    sb.c_customer_id,
    sb.ca_city,
    sb.cc_state,
    sb.cd_credit_rating,
    sb.sm_ship_mode_id,
    sb.w_warehouse_id,
    sb.p_promo_name,
    sb.sum_cs_net_paid + sb.sum_ws_net_paid AS total_sales,
    sb.sum_cs_net_profit + sb.sum_ws_net_profit AS total_profit,
    sb.sum_store_return_amt + sb.sum_web_return_amt AS total_return_amount,
    sb.total_inventory_qty,
    CASE
        WHEN (sb.sum_cs_net_profit + sb.sum_ws_net_profit) > 5000 THEN 'High'
        WHEN (sb.sum_cs_net_profit + sb.sum_ws_net_profit) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY sb.i_category ORDER BY (sb.sum_cs_net_profit + sb.sum_ws_net_profit) DESC) AS profit_rank,
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_item_sk = sb.i_item_sk) AS total_item_web_return_amt
FROM sales_base sb
ORDER BY profit_rank, total_sales DESC
LIMIT 100
