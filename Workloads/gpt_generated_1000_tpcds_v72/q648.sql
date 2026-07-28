/*
Goal: Calculate quarterly profit per store for the fiscal year 2001, compare it with inventory on‑hand and total return losses, rank stores by profit, and show how many returns each store had in the same quarter.
*/
WITH joined_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_gmt_offset,
        d.d_year,
        d.d_quarter_seq,
        ss.ss_net_profit,
        ss.ss_quantity,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        p.p_discount_active,
        r.r_reason_desc,
        ws.ws_net_paid,
        ws.ws_order_number,
        sm.sm_ship_mode_id,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE d.d_year = 2001
      AND s.s_gmt_offset = -5.00
      AND i.i_brand = 'Brand#23'
      AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
    j.s_store_name,
    j.d_year,
    j.d_quarter_seq,
    SUM(j.ss_net_profit) AS total_profit,
    SUM(j.inv_quantity_on_hand) AS total_inventory,
    SUM(j.cr_net_loss + j.sr_net_loss + j.wr_net_loss) AS total_loss,
    COUNT(DISTINCT j.ws_order_number) AS order_cnt,
    RANK() OVER (PARTITION BY j.d_year ORDER BY SUM(j.ss_net_profit) DESC) AS profit_rank,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE sr2.sr_store_sk = j.s_store_sk
          AND d2.d_year = j.d_year
          AND d2.d_quarter_seq = j.d_quarter_seq
    ) AS returns_in_quarter
FROM joined_data j
GROUP BY j.s_store_name, j.d_year, j.d_quarter_seq, j.s_store_sk
HAVING SUM(j.ss_quantity) > 1000
ORDER BY total_profit DESC
LIMIT 100
