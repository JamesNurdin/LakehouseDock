WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        row_number() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_profit DESC) AS rn_profit_rank,
        (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_net_profit,
        l.max_store_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT max(ss3.ss_net_profit) AS max_store_profit
        FROM store_sales ss3
        WHERE ss3.ss_store_sk = s.s_store_sk
    ) l
),
returns_union AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        hd_refunded.hd_income_band_sk,
        ib_refunded.ib_lower_bound,
        ib_refunded.ib_upper_bound,
        cc.cc_call_center_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN income_band ib_refunded ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amount,
        hd_refunded.hd_income_band_sk,
        ib_refunded.ib_lower_bound,
        ib_refunded.ib_upper_bound,
        NULL AS cc_call_center_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN income_band ib_refunded ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.i_item_id,
    sa.i_category,
    sa.i_brand,
    sa.rn_profit_rank,
    sa.ss_quantity,
    sa.ss_net_paid,
    sa.ss_net_profit,
    ru.return_quantity,
    ru.return_amount,
    COALESCE(ru.cc_call_center_id, 'N/A') AS call_center_id,
    sa.overall_avg_net_profit,
    sa.max_store_profit
FROM sales_agg sa
LEFT JOIN returns_union ru
    ON ru.i_item_sk = sa.i_item_sk
    AND ru.hd_income_band_sk = sa.hd_income_band_sk
ORDER BY sa.ss_net_profit DESC
LIMIT 100
