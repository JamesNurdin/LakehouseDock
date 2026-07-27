WITH filtered AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_division_name,
        cc.cc_street_number,
        cr.cr_return_ship_cost,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_tax,
        ss.ss_ext_sales_price,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        p.p_promo_name,
        p.p_discount_active
    FROM call_center cc
    JOIN catalog_returns cr
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_division_name IN ('ese', 'cally')
      AND cc.cc_street_number IN ('666', '860')
      AND cr.cr_return_ship_cost > 100
      AND cr.cr_store_credit < 200
      AND ss.ss_ext_wholesale_cost BETWEEN 500 AND 5000
      AND ss.ss_ext_tax < 10
      AND hd.hd_dep_count >= 2
      AND p.p_discount_active = 'Y'
)
SELECT
    cc_division_name,
    cc_call_center_id,
    p_promo_name,
    hd_buy_potential,
    SUM(cr_return_quantity) AS total_return_qty,
    SUM(sr_return_quantity) AS total_store_return_qty,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(cr_net_loss + sr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr_net_loss + sr_net_loss) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (PARTITION BY cc_division_name ORDER BY SUM(cr_net_loss + sr_net_loss) DESC) AS loss_rank_div
FROM filtered
GROUP BY
    cc_division_name,
    cc_call_center_id,
    p_promo_name,
    hd_buy_potential
ORDER BY
    cc_division_name,
    loss_rank_div
