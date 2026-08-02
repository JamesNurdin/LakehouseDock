WITH base AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_state AS store_state,
        i.i_item_id AS item_id,
        i.i_category AS category,
        i.i_color AS i_color,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        ss.ss_net_profit AS store_net_profit,
        cs.cs_net_profit AS catalog_net_profit,
        wr.wr_return_amt AS return_amt,
        inv.inv_quantity_on_hand AS inventory_qty
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ib.ib_lower_bound >= 50000
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = i.i_item_sk
            AND cs2.cs_sold_date_sk = d.d_date_sk
            AND cs2.cs_quantity > 0
      )
),
agg AS (
    SELECT
        store_id,
        store_name,
        store_state,
        item_id,
        category,
        i_color,
        d_year,
        d_month_seq,
        d_day_name,
        SUM(store_net_profit) AS total_store_profit,
        SUM(catalog_net_profit) AS total_catalog_profit,
        SUM(return_amt) AS total_return_amount,
        SUM(inventory_qty) AS total_inventory_on_hand
    FROM base
    GROUP BY store_id, store_name, store_state, item_id, category, i_color, d_year, d_month_seq, d_day_name
)
SELECT
    store_id,
    store_name,
    store_state,
    item_id,
    category,
    total_store_profit,
    total_catalog_profit,
    total_return_amount,
    total_inventory_on_hand,
    d_year,
    d_month_seq,
    d_day_name,
    ROW_NUMBER() OVER (PARTITION BY store_state ORDER BY total_store_profit DESC) AS store_profit_rn,
    RANK() OVER (PARTITION BY category ORDER BY total_store_profit DESC) AS category_profit_rank,
    CASE
        WHEN total_store_profit > 0 THEN 'POSITIVE'
        WHEN total_store_profit = 0 THEN 'ZERO'
        ELSE 'NEGATIVE'
    END AS profit_sign,
    color
FROM agg
CROSS JOIN UNNEST(split(i_color, ',')) AS t(color)
WHERE total_store_profit > 0
ORDER BY total_store_profit DESC
LIMIT 100
