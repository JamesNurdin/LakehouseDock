WITH base AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        i.i_item_id,
        i.i_current_price,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        ca.ca_state,
        sm.sm_type,
        p.p_discount_active,
        ss.ss_quantity AS store_qty,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_quantity AS web_qty,
        ws.ws_net_paid AS web_net_paid,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        -- CASE expression to flag profitability of the combined sale
        CASE WHEN (COALESCE(ss.ss_net_paid,0) + COALESCE(ws.ws_net_paid,0)) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        -- correlated scalar subquery: total inventory on the same item & date
        (SELECT SUM(inv2.inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_item_sk = i.i_item_sk
           AND inv2.inv_date_sk = d.d_date_sk) AS total_inventory_on_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state = 'TX'
      AND p.p_discount_active = 'Y'
      AND hd.hd_buy_potential = '1001-5000'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    profit_flag,
    SUM(store_net_paid) AS total_store_sales,
    SUM(web_net_paid)   AS total_web_sales,
    SUM(COALESCE(store_qty,0) + COALESCE(web_qty,0)) AS total_quantity_sold,
    SUM(total_inventory_on_date) AS total_inventory_on_date,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
FROM base
GROUP BY ROLLUP (d_year, d_month_seq, i_category, profit_flag)
ORDER BY d_year, d_month_seq, i_category
LIMIT 100
