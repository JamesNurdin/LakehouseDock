WITH filtered_returns AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        wr.wr_net_loss,
        wp.wp_url
    FROM web_returns AS wr
    JOIN web_sales AS ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN household_demographics AS hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page AS wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site AS wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE regexp_like(wp.wp_url, 'promo')
      AND wsite.web_name LIKE 'A%'
) 
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    COUNT(*) AS return_cnt,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_net_loss) AS avg_net_loss,
    regexp_extract(MIN(wp_url), 'https?://([^/]+)/', 1) AS sample_domain
FROM filtered_returns
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
HAVING SUM(wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
