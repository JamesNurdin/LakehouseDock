WITH ss_agg AS (
    SELECT ss_item_sk,
           ss_promo_sk,
           SUM(ss_net_paid) AS total_net_paid,
           SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_item_sk, ss_promo_sk
)
SELECT
    i1.i_item_id,
    i1.i_product_name,
    p.p_promo_name,
    t_cr.t_hour,
    r_cr.r_reason_desc AS catalog_return_reason,
    SUM(DISTINCT cr.cr_net_loss) AS catalog_total_net_loss,
    r_wr.r_reason_desc AS web_return_reason,
    SUM(DISTINCT wr.wr_net_loss) AS web_total_net_loss,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit,
    wp.wp_url,
    i2.i_brand
FROM ss_agg
JOIN item i1 ON ss_agg.ss_item_sk = i1.i_item_sk
JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN item i2 ON p.p_item_sk = i2.i_item_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i1.i_item_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN web_returns wr ON wr.wr_item_sk = i1.i_item_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
GROUP BY
    i1.i_item_id,
    i1.i_product_name,
    p.p_promo_name,
    t_cr.t_hour,
    r_cr.r_reason_desc,
    r_wr.r_reason_desc,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit,
    wp.wp_url,
    i2.i_brand
ORDER BY ss_agg.total_net_paid DESC
LIMIT 100
