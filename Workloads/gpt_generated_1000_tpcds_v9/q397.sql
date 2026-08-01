WITH combined AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        d.d_year,
        s.s_store_id,
        s.s_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        wp.wp_image_count,
        ss.ss_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        (COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0) - COALESCE(cr.cr_net_loss, 0)) AS total_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_closure
        ON s.s_closed_date_sk = d_closure.d_date_sk
    LEFT JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 10 AND 100
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5001-10000'
      AND wp.wp_image_count >= 4
      AND ss.ss_quantity > 1
      AND ws.ws_quantity > 1
),
per_item_year AS (
    SELECT
        i_item_id,
        i_item_desc,
        d_year,
        SUM(total_profit) AS sum_total_profit,
        COUNT(*) AS txn_count,
        AVG(total_profit) AS avg_total_profit
    FROM combined
    GROUP BY i_item_id, i_item_desc, d_year
)
SELECT
    i_item_id,
    i_item_desc,
    d_year,
    sum_total_profit,
    avg_total_profit,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sum_total_profit DESC) AS profit_rank_by_year
FROM per_item_year
WHERE sum_total_profit > 0
ORDER BY d_year, sum_total_profit DESC
LIMIT 100
