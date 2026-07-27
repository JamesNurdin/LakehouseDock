WITH cr_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_returning_cdemo_sk,
        cr_returning_hdemo_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount)          AS total_return_amount,
        COUNT(*)                       AS return_cnt
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_returned_date_sk, cr_returning_cdemo_sk, cr_returning_hdemo_sk, cr_ship_mode_sk
),
wr_agg AS (
    SELECT
        wr_returned_date_sk,
        wr_returning_cdemo_sk,
        wr_web_page_sk,
        SUM(wr_return_amt)            AS total_web_return_amt,
        COUNT(*)                       AS web_return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_returned_date_sk, wr_returning_cdemo_sk, wr_web_page_sk
)
SELECT DISTINCT
    d.d_year,
    sm.sm_code,
    cd.cd_gender,
    hd.hd_buy_potential,
    ws.web_name,
    p.p_promo_name,
    cr_agg.total_return_amount,
    cr_agg.return_cnt,
    wr_agg.total_web_return_amt,
    wr_agg.web_return_cnt,
    CASE
        WHEN (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') > 5 THEN 'HIGH'
        ELSE 'LOW'
    END                                   AS promo_activity_level,
    ROUND(cr_agg.total_return_amount / NULLIF(cr_agg.return_cnt, 0), 2) AS avg_return_amount
FROM cr_agg
JOIN ship_mode sm
    ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON cr_agg.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cr_agg.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN wr_agg
    ON cr_agg.cr_returned_date_sk = wr_agg.wr_returned_date_sk
   AND cr_agg.cr_returning_cdemo_sk = wr_agg.wr_returning_cdemo_sk
JOIN web_page wp
    ON wr_agg.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d
    ON cr_agg.cr_returned_date_sk = d.d_date_sk
   AND wr_agg.wr_returned_date_sk = d.d_date_sk
   AND wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE sm.sm_code = 'AIR'
  AND wp.wp_autogen_flag = 'Y'
  AND cd.cd_gender = 'M'
  AND d.d_year = 2001
  AND ws.web_state = 'CA'
ORDER BY cr_agg.total_return_amount DESC
LIMIT 100
