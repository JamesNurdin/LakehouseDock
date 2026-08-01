WITH cr_sample AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
first_part AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        sm.sm_type,
        w.w_warehouse_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        p.p_promo_id,
        r.r_reason_desc,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        (SELECT COUNT(*)
         FROM store_returns sr_sub
         WHERE sr_sub.sr_customer_sk = c.c_customer_sk
           AND sr_sub.sr_return_quantity > 5) AS high_return_cnt
    FROM cr_sample cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_type = 'OVERNIGHT'
      AND w.w_zip = '74136'
      AND p.p_channel_tv = 'N'
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc LIKE '%damage%'
      AND c.c_birth_year BETWEEN 1950 AND 1960
),
second_part AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        CAST(NULL AS varchar) AS sm_type,
        CAST(NULL AS integer) AS w_warehouse_sk,
        sr.sr_returned_date_sk AS metric_date_sk,
        CAST(NULL AS decimal(7,2)) AS ws_net_profit,
        sr.sr_return_quantity AS ws_quantity,
        CAST(NULL AS varchar) AS p_promo_id,
        r.r_reason_desc,
        CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS profit_flag,
        CAST(NULL AS integer) AS high_return_cnt,
        (SELECT COUNT(*)
         FROM web_sales ws_sub
         WHERE ws_sub.ws_bill_customer_sk = c.c_customer_sk
           AND ws_sub.ws_quantity > 10) AS high_sales_cnt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ib.ib_upper_bound IS NOT NULL
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk >= 2
      AND r.r_reason_desc IS NOT NULL
      AND c.c_birth_month = 7
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    final.c_customer_sk,
    final.sm_type,
    final.source,
    final.p_promo_id,
    final.total_profit,
    final.total_quantity,
    final.rows_cnt,
    DENSE_RANK() OVER (PARTITION BY final.source ORDER BY final.total_profit DESC) AS profit_rank
FROM (
    SELECT
        c_customer_sk,
        sm_type,
        source,
        p_promo_id,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity,
        COUNT(*) AS rows_cnt
    FROM (
        SELECT
            c_customer_sk,
            c_birth_year,
            cd_gender,
            hd_income_band_sk,
            ib_lower_bound,
            sm_type,
            w_warehouse_sk,
            ws_sold_date_sk AS metric_date_sk,
            ws_net_profit,
            ws_quantity,
            p_promo_id,
            r_reason_desc,
            profit_flag,
            high_return_cnt,
            CAST(NULL AS integer) AS high_sales_cnt,
            'catalog' AS source
        FROM first_part
        UNION DISTINCT
        SELECT
            c_customer_sk,
            c_birth_year,
            cd_gender,
            hd_income_band_sk,
            ib_lower_bound,
            sm_type,
            w_warehouse_sk,
            metric_date_sk,
            ws_net_profit,
            ws_quantity,
            p_promo_id,
            r_reason_desc,
            profit_flag,
            CAST(NULL AS integer) AS high_return_cnt,
            high_sales_cnt,
            'store' AS source
        FROM second_part
    ) u
    GROUP BY GROUPING SETS (
        (c_customer_sk, sm_type, source),
        (p_promo_id, source)
    )
) final
ORDER BY profit_rank
OFFSET 0 FETCH NEXT 100 ROWS ONLY
