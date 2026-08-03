WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
),
base AS (
    SELECT
        d_cs.d_year,
        i.i_category,
        w.w_warehouse_name,
        p.p_channel_press,
        SUM(cs.cs_ext_sales_price)                                     AS catalog_sales_amount,
        SUM(COALESCE(sr.sr_return_amt, 0))                             AS store_return_amount,
        SUM(COALESCE(wr.wr_return_amt, 0))                             AS web_return_amount,
        SUM(COALESCE(inv_agg.total_on_hand, 0))                        AS inventory_on_hand,
        SUM(cs.cs_net_profit)                                          AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_cs               ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN item i                      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                 ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w                 ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp             ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr    ON cr.cr_order_number = cs.cs_order_number
                                   AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r_cr           ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_sales ss        ON ss.ss_item_sk = i.i_item_sk
                                   AND ss.ss_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN store_returns sr      ON sr.sr_ticket_number = ss.ss_ticket_number
                                   AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r_sr           ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk
                                   AND ws.ws_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN web_returns wr        ON wr.wr_order_number = ws.ws_order_number
                                   AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r_wr           ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inv_agg               ON inv_agg.inv_item_sk = i.i_item_sk
                                   AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_cs.d_year = 2001
      AND p.p_channel_press = 'N'
      AND i.i_color = 'Red'
    GROUP BY ROLLUP (d_cs.d_year, i.i_category, w.w_warehouse_name, p.p_channel_press)
)
SELECT
    d_year,
    i_category,
    w_warehouse_name,
    p_channel_press,
    catalog_sales_amount,
    store_return_amount,
    web_return_amount,
    inventory_on_hand,
    CASE WHEN total_net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_level,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY catalog_sales_amount DESC) AS category_sales_rank,
    LAG(inventory_on_hand) OVER (PARTITION BY w_warehouse_name ORDER BY d_year) AS prev_inventory_on_hand
FROM base
ORDER BY d_year, i_category, w_warehouse_name
LIMIT 100
