WITH base AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        d.d_year,
        d.d_date,
        i.i_item_id,
        i.i_product_name,
        i.i_brand_id,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        cc.cc_market_manager,
        p.p_promo_name,
        p.p_channel_tv,
        r.r_reason_desc,
        hd_sales.hd_income_band_sk AS sales_income_band,
        hd_refund.hd_income_band_sk AS refund_income_band,
        ss.ss_quantity,
        ss.ss_net_profit,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_sales
        ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id = 260
      AND w.w_state = 'CA'
      AND cc.cc_market_manager = 'Gary Colburn'
      AND p.p_channel_tv = 'Y'
      AND hd_sales.hd_income_band_sk BETWEEN 10 AND 20
)
SELECT
    i_item_id,
    i_product_name,
    w_warehouse_id,
    w_warehouse_name,
    SUM(ss_net_profit) AS total_sales_profit,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ss_net_profit) - SUM(cr_return_amount) AS net_total,
    CASE WHEN SUM(ss_net_profit) - SUM(cr_return_amount) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY (SUM(ss_net_profit) - SUM(cr_return_amount)) DESC) AS warehouse_item_rank
FROM base
GROUP BY
    i_item_id,
    i_product_name,
    w_warehouse_id,
    w_warehouse_name
ORDER BY net_total DESC
LIMIT 100
