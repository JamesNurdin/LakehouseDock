-- Goal: Analyze total return amount and net loss by year, item category, gender and income band, 
-- combining catalog and store returns, promotions, inventory and web site activity, 
-- while demonstrating advanced SQL features such as CTEs, table sampling, right joins, 
-- case expressions, scalar subqueries and existence checks.
WITH
    catalog_sample AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_return_amount,
            cr.cr_net_loss,
            d_cr.d_year AS cr_year,
            i.i_category,
            i.i_item_id,
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_income_band_sk,
            cc.cc_call_center_sk,
            sm.sm_ship_mode_sk
        FROM catalog_returns cr
        TABLESAMPLE BERNOULLI (10)
        JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    ),
    store_ret AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_item_sk,
            sr.sr_return_amt,
            sr.sr_net_loss,
            d_sr.d_year AS sr_year,
            i.i_category AS sr_category,
            c.c_customer_id AS sr_customer_id,
            cd.cd_gender AS sr_gender,
            hd.hd_income_band_sk AS sr_income_band_sk,
            s.s_store_name,
            s.s_store_sk
        FROM store_returns sr
        RIGHT JOIN store s ON sr.sr_store_sk = s.s_store_sk
        LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        LEFT JOIN item i ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    )
SELECT
    d.d_year,
    i.i_category,
    cs.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(COALESCE(cs.cr_return_amount, 0) + COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(cs.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
    CASE
        WHEN SUM(COALESCE(cs.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0)) > 100000 THEN 'High'
        ELSE 'Low'
    END AS loss_severity,
    COUNT(DISTINCT cs.c_customer_id) AS distinct_customers
FROM catalog_sample cs
JOIN store_ret sr ON cs.cr_item_sk = sr.sr_item_sk
JOIN item i ON cs.cr_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cr_returned_date_sk = d.d_date_sk
JOIN income_band ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE cs.cr_return_amount > (
        SELECT AVG(cr_return_amount)
        FROM catalog_returns
        WHERE cr_returned_date_sk = 2452223
    )
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    d.d_year,
    i.i_category,
    cs.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_net_loss DESC
LIMIT 100
