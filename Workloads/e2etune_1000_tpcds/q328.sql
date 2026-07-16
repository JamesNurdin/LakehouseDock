WITH filtered_returns AS (
    SELECT
        cr_call_center_sk,
        cr_returned_date_sk,
        cr_return_amount,
        cr_net_loss,
        cr_return_quantity,
        cr_fee,
        cr_return_ship_cost,
        cr_return_amt_inc_tax,
        cr_order_number,
        cr_item_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450800 AND 2451200
),
filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_state,
        cc_manager,
        cc_class,
        cc_zip
    FROM call_center
    WHERE cc_manager = 'Bob Belcher'
      AND cc_class = 'large'
)
SELECT
    cc.cc_state,
    cc.cc_manager,
    date_trunc('month', date_add('day', fr.cr_returned_date_sk, date '1970-01-01')) AS return_month,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_quantity) AS avg_return_qty,
    SUM(fr.cr_fee) AS total_fee,
    SUM(fr.cr_return_ship_cost) AS total_ship_cost,
    SUM(fr.cr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG((SELECT avg(p.p_cost) FROM promotion p WHERE p.p_item_sk = fr.cr_item_sk)) AS avg_promo_cost,
    AVG((SELECT avg(s.s_tax_percentage) FROM store s WHERE s.s_zip = cc.cc_zip)) AS avg_store_tax_pct,
    SUM(fr.cr_net_loss) / NULLIF(SUM(fr.cr_return_amount), 0) AS net_loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY SUM(fr.cr_return_amount) DESC) AS state_rank
FROM filtered_returns fr
JOIN filtered_cc cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
GROUP BY
    cc.cc_state,
    cc.cc_manager,
    date_trunc('month', date_add('day', fr.cr_returned_date_sk, date '1970-01-01'))
HAVING SUM(fr.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
