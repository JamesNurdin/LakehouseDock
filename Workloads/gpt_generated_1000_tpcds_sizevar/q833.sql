WITH cr AS (
   SELECT
       cr.cr_item_sk,
       cr.cr_returned_date_sk,
       cr.cr_return_amount,
       cr.cr_net_loss,
       i.i_brand,
       i.i_category,
       cust_ref.c_customer_sk    AS refunded_cust_sk,
       cust_ref.c_first_name    AS refunded_first_name,
       cust_ret.c_customer_sk    AS returning_cust_sk,
       cust_ret.c_first_name    AS returning_first_name,
       hd_ref.hd_vehicle_count  AS refunded_vehicle_cnt,
       hd_ret.hd_vehicle_count  AS returning_vehicle_cnt,
       w.w_warehouse_name,
       r.r_reason_desc,
       ib_ref.ib_lower_bound    AS refunded_income_lower,
       ib_ret.ib_upper_bound    AS returning_income_upper
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
   JOIN customer cust_ret ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
   JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
   JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
),

sr AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_returned_date_sk,
       sr.sr_return_amt,
       i2.i_brand,
       i2.i_category,
       cust2.c_customer_sk,
       cust2.c_first_name,
       hd2.hd_vehicle_count,
       r2.r_reason_desc,
       ib_sr.ib_lower_bound
   FROM store_returns sr
   JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
   JOIN customer cust2 ON sr.sr_customer_sk = cust2.c_customer_sk
   JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
   JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
   JOIN income_band ib_sr ON hd2.hd_income_band_sk = ib_sr.ib_income_band_sk
),

union_returns AS (
   SELECT cr_item_sk AS item_sk, cr_return_amount AS return_amt FROM cr
   UNION DISTINCT
   SELECT sr_item_sk AS item_sk, sr_return_amt AS return_amt FROM sr
),

intersect_keys AS (
   SELECT cr_item_sk AS item_sk FROM cr
   INTERSECT
   SELECT sr_item_sk FROM sr
),

except_keys AS (
   SELECT cr_item_sk FROM cr
   EXCEPT
   SELECT sr_item_sk FROM sr
)

SELECT
    ik.item_sk,
    i3.i_brand,
    i3.i_category,
    COUNT(*)                              AS total_transactions,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END) AS high_value_returns,
    AVG(u.return_amt) FILTER (WHERE u.return_amt IS NOT NULL)   AS avg_union_return_amt,
    (SELECT AVG(sr2.sr_return_amt_inc_tax)
       FROM store_returns sr2
       WHERE sr2.sr_item_sk = ik.item_sk)                AS avg_store_return_amt_inc_tax
FROM intersect_keys ik
JOIN cr ON cr.cr_item_sk = ik.item_sk
JOIN sr ON sr.sr_item_sk = ik.item_sk
JOIN item i3 ON i3.i_item_sk = ik.item_sk
JOIN union_returns u ON u.item_sk = ik.item_sk
GROUP BY ik.item_sk, i3.i_brand, i3.i_category
ORDER BY total_transactions DESC
LIMIT 100
