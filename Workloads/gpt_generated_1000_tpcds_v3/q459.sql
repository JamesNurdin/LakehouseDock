WITH inv_agg AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        MAX(d_inventory.d_date) AS latest_inventory_date
    FROM inventory inv
    JOIN date_dim d_inventory ON inv.inv_date_sk = d_inventory.d_date_sk
    GROUP BY inv.inv_item_sk
),

sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        d_sales.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amt,
        COALESCE(SUM(inv_agg.total_on_hand), 0) AS total_inventory_on_hand,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM date_dim d_sales
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_sales.d_year = 2000
      AND i.i_current_price > 100
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_category, i.i_brand, i.i_current_price, d_sales.d_year
    HAVING SUM(ws.ws_ext_sales_price) > 0
)

SELECT
    i_item_id,
    i_item_desc,
    i_category,
    i_brand,
    i_current_price,
    d_year,
    total_sales,
    total_net_profit,
    total_return_amt,
    total_inventory_on_hand,
    distinct_orders,
    (
        SELECT COUNT(DISTINCT r2.r_reason_id)
        FROM web_returns wr2
        JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE wr2.wr_item_sk = sales_agg.i_item_sk
    ) AS distinct_return_reasons,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_profit DESC) AS category_profit_rank
FROM sales_agg
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE sr.sr_item_sk = sales_agg.i_item_sk
      AND d_sr.d_year = 2000
      AND sr.sr_return_quantity > 0
)
ORDER BY total_net_profit DESC
LIMIT 100
