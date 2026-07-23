WITH sales_agg AS (
    SELECT
        i.i_color AS i_color,
        i.i_units AS i_units,
        concat(i.i_color, '-', i.i_units) AS color_units,
        regexp_extract(i.i_item_desc, '^(\w+)', 1) AS first_word_desc,
        substring(i.i_item_id, 1, 5) AS item_id_prefix,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(i.i_color, '^s')
      AND wp.wp_url LIKE '%sale%'
    GROUP BY
        i.i_color,
        i.i_units,
        i.i_item_desc,
        i.i_item_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential
)
SELECT
    color_units,
    i_color,
    i_units,
    first_word_desc,
    item_id_prefix,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    total_net_paid,
    total_net_profit,
    sales_cnt,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
