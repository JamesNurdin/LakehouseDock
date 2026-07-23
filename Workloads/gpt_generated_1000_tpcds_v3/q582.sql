WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        w.w_warehouse_id,
        w.w_city AS warehouse_city,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        wp.wp_url,
        wp.wp_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
        ON d.d_date_sk = cr.cr_returned_date_sk
        AND i.i_item_sk = cr.cr_item_sk
        AND hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
        AND d.d_date_sk = inv.inv_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON d.d_date_sk = wp.wp_creation_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 50.00
      AND w.w_city = 'Seattle'
      AND ib.ib_upper_bound >= 50000
)
SELECT
    d_date,
    s_store_id,
    s_store_name,
    i_product_name,
    i_current_price,
    ss_quantity,
    ss_net_profit,
    cr_return_quantity,
    inv_quantity_on_hand,
    wp_url,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY ss_net_profit DESC) AS daily_store_profit_rank,
    SUM(ss_net_profit) OVER (PARTITION BY s_store_id ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_profit
FROM base
ORDER BY d_date DESC, daily_store_profit_rank
LIMIT 100
