WITH item_returns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
)
SELECT
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    SUM(ir.total_return_amt) AS agg_return_amt,
    SUM(ir.return_cnt)      AS agg_return_cnt,
    COUNT(*)                AS rows_cnt,
    SUM(wr.wr_return_tax)   AS total_return_tax,
    AVG(i.i_current_price)  AS avg_price
FROM web_returns wr
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN item_returns ir
    ON ir.wr_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_cur_ref
    ON c_ref.c_current_cdemo_sk = cd_cur_ref.cd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_cur_ref
    ON c_ref.c_current_hdemo_sk = hd_cur_ref.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
      AND p2.p_discount_active = 'Y'
      AND p2.p_cost < i.i_current_price
)
  AND i.i_current_price > 10
GROUP BY ROLLUP (i.i_category, i.i_brand, p.p_promo_name)
ORDER BY i.i_category, i.i_brand, p.p_promo_name
