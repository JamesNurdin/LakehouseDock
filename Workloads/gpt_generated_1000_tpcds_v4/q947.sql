WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_brand AS brand,
        cd.cd_gender AS gender,
        ib.ib_lower_bound AS income_lower_bound,
        CASE WHEN i.i_current_price > 100 THEN 'expensive' ELSE 'regular' END AS price_category,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(CASE WHEN i.i_current_price > 100 THEN 1 ELSE 0 END) AS high_price_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                         AND wr.wr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND r.r_reason_id LIKE 'AAAA%'
      AND hd.hd_dep_count <= 5
      AND ib.ib_lower_bound >= 30000
      AND s.s_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
      AND wsite.web_state = 'CA'
    GROUP BY
        s.s_store_name,
        i.i_brand,
        cd.cd_gender,
        ib.ib_lower_bound,
        CASE WHEN i.i_current_price > 100 THEN 'expensive' ELSE 'regular' END
)
SELECT
    store_name,
    AVG(total_sales) AS avg_sales,
    SUM(total_store_loss) AS sum_loss,
    SUM(high_price_cnt) AS total_high_price_items
FROM base
GROUP BY store_name
HAVING AVG(total_sales) > 5000
ORDER BY avg_sales DESC
LIMIT 100
