WITH joined_all AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        c.c_customer_id,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ws.ws_net_paid,
        ws.ws_net_profit,
        inv.inv_quantity_on_hand,
        wp.wp_type,
        r.r_reason_desc,
        wr.wr_return_quantity,
        ib.ib_upper_bound,
        hd.hd_vehicle_count
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451220 AND 2451500
      AND i.i_current_price > 100
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 120000
      AND wp.wp_type = 'Content'
),
item_agg AS (
    SELECT
        i_brand,
        i_category,
        SUM(ss_net_paid) AS total_store_net_paid,
        SUM(ws_net_paid) AS total_web_net_paid,
        SUM(ss_net_profit) AS total_store_net_profit,
        SUM(ws_net_profit) AS total_web_net_profit,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        SUM(inv_quantity_on_hand) AS total_inventory,
        SUM(wr_return_quantity) AS total_return_qty
    FROM joined_all
    GROUP BY i_brand, i_category
)
SELECT
    i_brand,
    i_category,
    (total_store_net_paid + total_web_net_paid) AS total_net_paid,
    (total_store_net_profit + total_web_net_profit) / NULLIF((total_store_net_paid + total_web_net_paid), 0) AS avg_profit_margin,
    distinct_customers,
    total_inventory,
    total_return_qty
FROM item_agg
WHERE (total_store_net_paid + total_web_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
