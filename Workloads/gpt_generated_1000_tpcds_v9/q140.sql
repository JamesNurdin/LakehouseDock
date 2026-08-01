WITH joined_data AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        i.i_category,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        p.p_discount_active,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        r.r_reason_desc,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        wp.wp_link_count,
        wp.wp_char_count,
        wsit.web_state,
        i.i_rec_start_date
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE i.i_current_price > 100.00
      AND ca.ca_state IN ('CA', 'TX')
      AND cd.cd_gender = 'F'
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_lower_bound >= 50000
      AND p.p_discount_active = 'Y'
      AND wp.wp_link_count > 10
      AND wsit.web_state = 'CA'
      AND i.i_rec_start_date >= DATE '2000-01-01'
)
SELECT
    ss_store_sk,
    i_item_sk,
    i_product_name,
    total_quantity,
    total_net_profit,
    avg_net_profit_per_sale,
    CASE WHEN total_net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    rank_by_profit
FROM (
    SELECT
        ss_store_sk,
        i_item_sk,
        i_product_name,
        SUM(ss_quantity) + COALESCE(SUM(ws_quantity), 0) AS total_quantity,
        SUM(ss_net_profit) + COALESCE(SUM(ws_net_profit), 0) AS total_net_profit,
        AVG(ss_net_profit) AS avg_net_profit_per_sale,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) + COALESCE(SUM(ws_net_profit), 0) DESC) AS rank_by_profit
    FROM joined_data
    GROUP BY ss_store_sk, i_item_sk, i_product_name
) t
WHERE rank_by_profit <= 10
ORDER BY ss_store_sk, rank_by_profit
LIMIT 100
