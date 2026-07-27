WITH joined AS (
    SELECT
        s.s_store_name,
        i.i_class,
        d_sr.d_year,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        p.p_promo_sk,
        wp.wp_autogen_flag,
        cp.cp_department,
        (
            SELECT COUNT(*)
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
        ) AS total_promos
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_sr.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE d_sr.d_year = 2001
      AND i.i_class = 'sports-apparel'
      AND wp.wp_autogen_flag = 'Y'
      AND cp.cp_department = 'DEPARTMENT'
      AND p.p_discount_active = 'Y'
)
SELECT
    s_store_name,
    i_class,
    SUM(sr_net_loss) AS store_return_loss,
    SUM(cr_net_loss) AS catalog_return_loss,
    SUM(wr_net_loss) AS web_return_loss,
    SUM(sr_net_loss + cr_net_loss + wr_net_loss) AS total_loss,
    COUNT(DISTINCT p_promo_sk) AS promo_count,
    MAX(total_promos) AS total_promos,
    RANK() OVER (ORDER BY SUM(sr_net_loss + cr_net_loss + wr_net_loss) DESC) AS loss_rank
FROM joined
GROUP BY GROUPING SETS (
    (s_store_name, i_class),
    (s_store_name),
    (i_class),
    ()
)
ORDER BY loss_rank
LIMIT 100
