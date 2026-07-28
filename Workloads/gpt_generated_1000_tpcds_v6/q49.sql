WITH base AS (
    SELECT
        s.s_store_id            AS store_id,
        cp.cp_catalog_page_number AS catalog_page_number,
        cs.cs_net_profit,
        cr.cr_return_amount,
        i.i_current_price,
        cd.cd_gender,
        hd.hd_income_band_sk,
        sm.sm_type,
        r.r_reason_desc
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_current_price > 50
      AND cd.cd_gender = 'F'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND s.s_state = 'CA'
      AND cp.cp_catalog_page_number IN (7, 17, 20)
      AND sm.sm_type = 'AIR'
      AND cr.cr_return_amount > 200
      AND cs.cs_net_profit > 0
),
agg AS (
    SELECT
        store_id,
        catalog_page_number,
        SUM(cs_net_profit)        AS total_net_profit,
        SUM(cr_return_amount)    AS total_return_amount,
        COUNT(*)                 AS transaction_cnt
    FROM base
    GROUP BY store_id, catalog_page_number
)
SELECT
    catalog_page_number,
    AVG(total_net_profit)       AS avg_profit_per_store,
    SUM(total_return_amount)    AS total_return_amount_all,
    COUNT(*)                    AS store_count
FROM agg
GROUP BY catalog_page_number
HAVING AVG(total_net_profit) > 1000
ORDER BY avg_profit_per_store DESC
LIMIT 100
