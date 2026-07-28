WITH base AS (
    SELECT
        t.t_time_sk,
        t.t_hour,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        ss.ss_net_profit AS store_profit,
        ws.ws_net_profit AS web_profit,
        sr.sr_net_loss AS store_return_loss,
        cr.cr_net_loss AS catalog_return_loss,
        wr.wr_net_loss AS web_return_loss,
        p.p_discount_active,
        r.r_reason_desc
    FROM time_dim t
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_return_time_sk = t.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
       AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
       AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_item_sk = i.i_item_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND hd.hd_income_band_sk >= 10
      AND i.i_current_price > 20
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    i_category,
    CASE
        WHEN SUM(total_profit) > 5000 THEN 'High'
        WHEN SUM(total_profit) > 0    THEN 'Medium'
        ELSE 'Low'
    END AS profit_level,
    SUM(total_profit) AS sum_profit,
    AVG(total_loss)   AS avg_loss,
    COUNT(DISTINCT i_item_sk) AS distinct_items
FROM (
    SELECT
        i_category,
        i_item_sk,
        (COALESCE(store_profit, 0) + COALESCE(web_profit, 0)) AS total_profit,
        (COALESCE(store_return_loss, 0) + COALESCE(catalog_return_loss, 0) + COALESCE(web_return_loss, 0)) AS total_loss
    FROM base
) agg
GROUP BY i_category
HAVING SUM(total_profit) > 1000
ORDER BY sum_profit DESC
LIMIT 100
