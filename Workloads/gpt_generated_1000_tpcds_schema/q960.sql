WITH
    agg_item AS (
        SELECT i_item_sk,
               COUNT(*) AS item_cnt,
               SUM(i_current_price) AS sum_price
        FROM item
        GROUP BY i_item_sk
    ),
    cr_sub AS (
        SELECT cr_item_sk
        FROM catalog_returns TABLESAMPLE BERNOULLI (10)
        WHERE cr_return_amount > 100
    ),
    wr_sub AS (
        SELECT wr_item_sk
        FROM web_returns
        WHERE wr_return_amt > 50
    ),
    intersect_items AS (
        SELECT cr_item_sk AS i_item_sk FROM cr_sub
        INTERSECT
        SELECT wr_item_sk FROM wr_sub
    ),
    catalog_part AS (
        SELECT
            i.i_item_id,
            i.i_class,
            i.i_brand,
            cc.cc_name,
            w.w_warehouse_name,
            r.r_reason_desc,
            cd_ref.cd_credit_rating,
            hd.hd_buy_potential,
            ib.ib_lower_bound,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
        FROM intersect_items it
        JOIN agg_item a ON it.i_item_sk = a.i_item_sk
        JOIN item i ON a.i_item_sk = i.i_item_sk
        JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        -- LATERAL array creation and UNNEST
        CROSS JOIN LATERAL (
            SELECT ARRAY[i.i_current_price, i.i_wholesale_cost] AS price_arr
        ) AS la
        CROSS JOIN UNNEST(la.price_arr) AS t(price)
        WHERE price > 0
        GROUP BY
            i.i_item_id,
            i.i_class,
            i.i_brand,
            cc.cc_name,
            w.w_warehouse_name,
            r.r_reason_desc,
            cd_ref.cd_credit_rating,
            hd.hd_buy_potential,
            ib.ib_lower_bound
    ),
    web_part AS (
        SELECT
            i.i_item_id,
            i.i_class,
            i.i_brand,
            NULL AS cc_name,
            NULL AS w_warehouse_name,
            r.r_reason_desc,
            cd_ref.cd_credit_rating,
            hd.hd_buy_potential,
            ib.ib_lower_bound,
            SUM(wr.wr_return_amt) AS total_return_amount,
            COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
        FROM intersect_items it
        JOIN agg_item a ON it.i_item_sk = a.i_item_sk
        JOIN item i ON a.i_item_sk = i.i_item_sk
        JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE EXISTS (
            SELECT 1 FROM catalog_returns cr_chk
            WHERE cr_chk.cr_item_sk = i.i_item_sk AND cr_chk.cr_return_amount > 200
        )
        GROUP BY
            i.i_item_id,
            i.i_class,
            i.i_brand,
            r.r_reason_desc,
            cd_ref.cd_credit_rating,
            hd.hd_buy_potential,
            ib.ib_lower_bound
    )
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM (
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM web_part
) AS final
ORDER BY total_return_amount DESC
LIMIT 50
