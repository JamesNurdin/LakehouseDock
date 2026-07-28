WITH promo_item AS (
        SELECT p.p_promo_sk, p.p_promo_name, p.p_channel_radio, p.p_item_sk
        FROM promotion p
    )
SELECT
    cp.cp_description,
    p_ws.p_promo_name,
    i_ss.i_category,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    array_agg(DISTINCT p_ss.p_channel_radio) AS radio_channels
FROM store_sales ss
JOIN item i_ss
    ON ss.ss_item_sk = i_ss.i_item_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i_ss.i_item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i_ss.i_item_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i_ss.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN promotion p_item
    ON p_item.p_item_sk = i_ss.i_item_sk
GROUP BY
    cp.cp_description,
    p_ws.p_promo_name,
    i_ss.i_category
ORDER BY store_net_profit DESC
LIMIT 100
