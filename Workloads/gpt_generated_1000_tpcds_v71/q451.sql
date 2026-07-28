/*
Goal: Analyze return losses across store, catalog, and web channels for the year 2001, broken down by various dimensions such as month, hour, item category and customer gender, and identify periods with positive net loss in the store channel.
*/
WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        i.i_category,
        cd.cd_gender,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss)   AS catalog_net_loss,
        SUM(wr.wr_net_loss)   AS web_net_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > 0 THEN 'POSITIVE'
            WHEN SUM(sr.sr_net_loss) < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS store_loss_sign
    FROM date_dim d
    LEFT JOIN store_returns sr      ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr   ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr       ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t           ON t.t_time_sk = COALESCE(sr.sr_return_time_sk, cr.cr_returned_time_sk, wr.wr_returned_time_sk)
    LEFT JOIN item i               ON i.i_item_sk = COALESCE(sr.sr_item_sk, cr.cr_item_sk, wr.wr_item_sk)
    LEFT JOIN customer c           ON c.c_customer_sk = COALESCE(
                                            sr.sr_customer_sk,
                                            cr.cr_refunded_customer_sk,
                                            cr.cr_returning_customer_sk,
                                            wr.wr_refunded_customer_sk,
                                            wr.wr_returning_customer_sk)
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ib           ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN promotion p              ON p.p_item_sk = i.i_item_sk
    LEFT JOIN reason r                 ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, cr.cr_reason_sk, wr.wr_reason_sk)
    LEFT JOIN ship_mode sm             ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN warehouse w              ON w.w_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN catalog_page cp          ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN web_page wp              ON wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND hd.hd_buy_potential = '5000+'
      AND ib.ib_upper_bound >= 150000
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY GROUPING SETS (
        (d.d_year, d.d_month_seq, t.t_hour, i.i_category, cd.cd_gender),
        (d.d_year, i.i_category),
        (d.d_year)
    )
)
SELECT *
FROM aggregated
WHERE store_net_loss > 0
ORDER BY d_year DESC, i_category
LIMIT 100
