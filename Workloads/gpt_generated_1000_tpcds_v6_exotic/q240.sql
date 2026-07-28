WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_state,
        cs.cs_net_profit AS catalog_net_profit,
        ws.ws_net_profit AS web_net_profit,
        cr.cr_net_loss AS catalog_return_loss,
        sr.sr_net_loss AS store_return_loss,
        wr.wr_net_loss AS web_return_loss,
        (
            SELECT avg(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_item_sales_price
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN income_band ib_sr
        ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_wr_ref
        ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
    JOIN household_demographics hd_wr_ref
        ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
    JOIN income_band ib_wr
        ON hd_wr_ref.hd_income_band_sk = ib_wr.ib_income_band_sk
    WHERE
        i.i_current_price > 10.00
        AND s.s_state = 'CA'
        AND ib.ib_lower_bound >= 40000
        AND cs.cs_quantity > 2
        AND ws.ws_quantity > 0
        AND sr.sr_returned_date_sk BETWEEN 2451000 AND 2452000
),
agg AS (
    SELECT
        i_category,
        ib_income_band_sk,
        s_state,
        SUM(catalog_net_profit) AS total_catalog_profit,
        SUM(web_net_profit) AS total_web_profit,
        SUM(catalog_return_loss) AS total_catalog_return_loss,
        SUM(store_return_loss) AS total_store_return_loss,
        SUM(web_return_loss) AS total_web_return_loss,
        AVG(avg_item_sales_price) AS avg_sales_price
    FROM base
    GROUP BY i_category, ib_income_band_sk, s_state
)
SELECT
    i_category,
    ib_income_band_sk,
    s_state,
    total_catalog_profit,
    total_web_profit,
    total_catalog_return_loss,
    total_store_return_loss,
    total_web_return_loss,
    (total_catalog_profit + total_web_profit) -
    (total_catalog_return_loss + total_store_return_loss + total_web_return_loss) AS net_contribution,
    avg_sales_price
FROM agg
WHERE
    (total_catalog_profit + total_web_profit) -
    (total_catalog_return_loss + total_store_return_loss + total_web_return_loss) > 0
    AND avg_sales_price > 50
ORDER BY net_contribution DESC
LIMIT 100
