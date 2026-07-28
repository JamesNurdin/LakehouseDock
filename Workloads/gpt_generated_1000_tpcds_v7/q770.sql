WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        i.i_item_sk,
        i.i_item_id,
        i.i_color,
        i.i_manufact,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        w.w_warehouse_id,
        p.p_promo_id,
        p.p_cost,
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_ext_ship_cost,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_order_number,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM customer c
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_customer_sk = c.c_customer_sk
    JOIN web_site site
      ON ws.ws_web_site_sk = site.web_site_sk
    WHERE i.i_color = 'wheat'
      AND hd.hd_vehicle_count > 0
      AND ws.ws_net_paid > 500
      AND p.p_cost BETWEEN 10 AND 100
      AND i.i_rec_start_date >= DATE '2000-01-01'
)
SELECT
    i_item_id,
    i_manufact,
    hd_buy_potential,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_quantity) AS total_quantity_sold,
    CASE
        WHEN hd_buy_potential = '>10000' THEN 'High'
        ELSE 'Other'
    END AS buy_potential_category,
    RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
FROM joined_data
GROUP BY
    i_item_id,
    i_manufact,
    hd_buy_potential
ORDER BY sales_rank
LIMIT 20
