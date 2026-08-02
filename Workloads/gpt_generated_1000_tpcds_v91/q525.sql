WITH promotion_loss AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d_sold.d_year AS year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc,
        s.s_store_name,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_net_loss > 0
      AND d_sold.d_year IN (2001, 2002)
      AND p.p_channel_tv = 'Y'
      AND sm.sm_code IN ('AIR', 'SEA')
    GROUP BY p.p_promo_sk,
             p.p_promo_name,
             d_sold.d_year,
             cc.cc_name,
             sm.sm_type,
             r.r_reason_desc,
             s.s_store_name,
             cd.cd_gender,
             hd.hd_income_band_sk
)

SELECT
    pl.p_promo_name,
    pl.year,
    pl.total_net_loss,
    RANK() OVER (PARTITION BY pl.year ORDER BY pl.total_net_loss DESC) AS promo_rank,
    CASE WHEN pl.total_net_loss > (SELECT AVG(total_net_loss) FROM promotion_loss) THEN 'Above Avg' ELSE 'Below Avg' END AS loss_category,
    pl.cc_name,
    pl.sm_type,
    pl.r_reason_desc,
    pl.s_store_name,
    pl.cd_gender AS gender,
    pl.hd_income_band_sk AS income_band,
    pl.return_count
FROM promotion_loss pl
WHERE pl.year = 2001

UNION

SELECT
    pl.p_promo_name,
    pl.year,
    pl.total_net_loss,
    RANK() OVER (PARTITION BY pl.year ORDER BY pl.total_net_loss DESC) AS promo_rank,
    CASE WHEN pl.total_net_loss > (SELECT AVG(total_net_loss) FROM promotion_loss) THEN 'Above Avg' ELSE 'Below Avg' END AS loss_category,
    pl.cc_name,
    pl.sm_type,
    pl.r_reason_desc,
    pl.s_store_name,
    pl.cd_gender AS gender,
    pl.hd_income_band_sk AS income_band,
    pl.return_count
FROM promotion_loss pl
WHERE pl.year = 2002

ORDER BY year, promo_rank
LIMIT 100
