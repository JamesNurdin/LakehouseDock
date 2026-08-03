WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ca.ca_state,
        s.s_store_name,
        s.s_state,
        t.t_hour,
        t.t_am_pm
    FROM store_sales ss
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0)
      AND i.i_current_price BETWEEN 20 AND 200
      AND ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity > 5
),
returns_joined AS (
    SELECT
        sb.*, 
        sr.sr_return_quantity,
        sr.sr_net_loss AS store_return_net_loss,
        wr.wr_return_quantity,
        wr.wr_net_loss AS web_return_net_loss,
        inv.inv_quantity_on_hand,
        wp.wp_url
    FROM sales_base sb
    LEFT JOIN store_returns sr
        ON sb.ss_ticket_number = sr.sr_ticket_number
       AND sb.ss_item_sk = sr.sr_item_sk
       AND sb.ss_store_sk = sr.sr_store_sk
    LEFT JOIN web_returns wr
        ON sb.ss_item_sk = wr.wr_item_sk
       AND sb.ss_sold_time_sk = wr.wr_returned_time_sk
    LEFT JOIN inventory inv
        ON sb.ss_item_sk = inv.inv_item_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE inv.inv_quantity_on_hand IS NOT NULL
)
SELECT
    rj.s_store_name,
    rj.s_state,
    rj.t_hour,
    rj.i_product_name,
    SUM(rj.ss_net_paid) AS total_net_paid,
    SUM(rj.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(rj.sr_return_quantity, 0)) AS total_store_returns_qty,
    SUM(COALESCE(rj.wr_return_quantity, 0)) AS total_web_returns_qty,
    CASE
        WHEN SUM(rj.ss_net_profit) > 10000 THEN 'High Profit'
        WHEN SUM(rj.ss_net_profit) < 0 THEN 'Loss'
        ELSE 'Normal'
    END AS profit_category,
    RANK() OVER (PARTITION BY rj.s_state ORDER BY SUM(rj.ss_net_paid) DESC) AS state_sales_rank,
    SUM(rj.inv_quantity_on_hand) OVER (PARTITION BY rj.s_store_name) AS store_inventory_total
FROM returns_joined rj
GROUP BY
    rj.s_store_name,
    rj.s_state,
    rj.t_hour,
    rj.i_product_name,
    rj.inv_quantity_on_hand
ORDER BY total_net_paid DESC
LIMIT 100
