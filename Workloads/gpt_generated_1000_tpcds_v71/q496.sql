WITH base AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        i.i_brand,
        i.i_current_price,
        p.p_promo_name,
        p.p_discount_active,
        cd.cd_gender,
        ss.ss_sales_price,
        cr.cr_return_amount,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_current_price > 100
      AND cr.cr_return_amount > 1000
),
agg AS (
    SELECT
        cc_name,
        cc_state,
        i_brand,
        cd_gender,
        p_promo_name,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(wr_return_amt) AS total_web_return,
        AVG(ss_sales_price) AS avg_sales_price
    FROM base
    GROUP BY cc_name, cc_state, i_brand, cd_gender, p_promo_name
)
SELECT
    cc_name,
    cc_state,
    i_brand,
    cd_gender,
    p_promo_name,
    total_catalog_return,
    total_web_return,
    avg_sales_price,
    CASE WHEN total_catalog_return > 5000 THEN 'High' ELSE 'Low' END AS return_category,
    RANK() OVER (PARTITION BY p_promo_name ORDER BY total_catalog_return DESC) AS return_rank
FROM agg
ORDER BY return_rank, total_catalog_return DESC
LIMIT 100
