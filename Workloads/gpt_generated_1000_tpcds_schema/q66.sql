WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential,
        p.p_promo_name,
        sm.sm_type,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim tp
      ON cs.cs_sold_time_sk = tp.t_time_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
     AND cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_returned_time_sk = tp.t_time_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss
      ON ss.ss_item_sk = cs.cs_item_sk
     AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_return_time_sk = tp.t_time_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = cs.cs_item_sk
     AND inv.inv_date_sk = d.d_date_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_returned_time_sk = tp.t_time_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 1998
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND hd.hd_income_band_sk = 5
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc = 'Did not like the model'
      AND sm.sm_type = 'AIR'
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        hd_buy_potential,
        p_promo_name,
        sm_type,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cr_return_amount) AS total_cr_return_amount,
        SUM(sr_return_amt) AS total_sr_return_amt,
        SUM(wr_return_amt) AS total_wr_return_amt,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM base
    GROUP BY CUBE (d_year, d_month_seq, hd_buy_potential, p_promo_name, sm_type)
)
SELECT
    d_year,
    d_month_seq,
    hd_buy_potential,
    p_promo_name,
    sm_type,
    total_net_paid,
    total_net_profit,
    total_cr_return_amount,
    total_sr_return_amt,
    total_wr_return_amt,
    order_cnt,
    avg_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rank_in_year
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
