WITH return_agg AS (
    SELECT
        p.p_promo_id,
        i.i_item_id,
        SUM(cr.cr_net_loss)               AS catalog_net_loss,
        SUM(sr.sr_net_loss)               AS store_net_loss,
        SUM(wr.wr_net_loss)               AS web_net_loss,
        COUNT(*) FILTER (WHERE cr.cr_net_loss IS NOT NULL) AS catalog_return_cnt,
        COUNT(*) FILTER (WHERE sr.sr_net_loss IS NOT NULL) AS store_return_cnt,
        COUNT(*) FILTER (WHERE wr.wr_net_loss IS NOT NULL) AS web_return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk

    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk

    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c_wr ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
    JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    JOIN customer_demographics cd_wr ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
    JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 100
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND wp.wp_autogen_flag = 'N'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY p.p_promo_id, i.i_item_id
)
,
item_totals AS (
    SELECT
        p_promo_id,
        i_item_id,
        (catalog_net_loss + store_net_loss + web_net_loss) AS total_net_loss,
        catalog_return_cnt,
        store_return_cnt,
        web_return_cnt
    FROM return_agg
)
SELECT
    it.p_promo_id,
    it.i_item_id,
    it.total_net_loss,
    CASE WHEN it.total_net_loss > 0 THEN 'Profit' ELSE 'Loss' END AS loss_category,
    (
        SELECT AVG(inner_tot.total_net_loss)
        FROM (
            SELECT (catalog_net_loss + store_net_loss + web_net_loss) AS total_net_loss
            FROM return_agg
            WHERE p_promo_id = it.p_promo_id
        ) inner_tot
    ) AS avg_promo_net_loss
FROM item_totals it
WHERE it.total_net_loss > (
    SELECT AVG(catalog_net_loss + store_net_loss + web_net_loss)
    FROM return_agg
)
ORDER BY it.total_net_loss DESC
LIMIT 100
