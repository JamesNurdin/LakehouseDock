WITH
  sales_base AS (
    SELECT
      ss.ss_sold_date_sk AS sold_date_sk,
      ss.ss_sold_time_sk AS sold_time_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_customer_sk AS customer_sk,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_profit AS net_profit,
      td.t_hour AS hour,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      p.p_promo_name
    FROM store_sales ss
    INNER JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    INNER JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  returns_base AS (
    SELECT
      cr.cr_returned_date_sk AS returned_date_sk,
      cr.cr_returned_time_sk AS returned_time_sk,
      cr.cr_item_sk AS item_sk,
      cr.cr_return_quantity AS quantity,
      cr.cr_refunded_cash AS amount,
      cr.cr_return_ship_cost AS ship_cost,
      td.t_hour AS hour,
      cc.cc_name AS call_center_name,
      sm.sm_carrier AS carrier,
      c.c_customer_sk AS customer_sk,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_upper_bound
    FROM catalog_returns cr
    FULL OUTER JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    INNER JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  union_sales_returns AS (
    SELECT
      sold_date_sk AS trans_date_sk,
      sold_time_sk AS trans_time_sk,
      item_sk,
      customer_sk AS cust_sk,
      quantity,
      net_paid AS amount,
      NULL AS carrier,
      p_promo_name AS promo_name,
      'sale' AS trans_type,
      hour AS t_hour
    FROM sales_base
    UNION DISTINCT
    SELECT
      returned_date_sk,
      returned_time_sk,
      item_sk,
      customer_sk,
      quantity,
      amount,
      carrier,
      NULL AS promo_name,
      'return' AS trans_type,
      hour
    FROM returns_base
  ),
  sales_cust_keys AS (
    SELECT DISTINCT customer_sk FROM sales_base
  ),
  returns_cust_keys AS (
    SELECT DISTINCT customer_sk FROM returns_base
  ),
  exclusive_sales_cust AS (
    SELECT customer_sk FROM sales_cust_keys
    EXCEPT
    SELECT customer_sk FROM returns_cust_keys
  ),
  common_cust AS (
    SELECT customer_sk FROM sales_cust_keys
    INTERSECT
    SELECT customer_sk FROM returns_cust_keys
  )
SELECT
  usr.trans_date_sk,
  usr.trans_time_sk,
  usr.item_sk,
  usr.cust_sk,
  usr.quantity,
  usr.amount,
  usr.trans_type,
  usr.t_hour,
  CASE WHEN usr.trans_type = 'sale' THEN 'POSITIVE' ELSE 'NEGATIVE' END AS sign_flag,
  ROW_NUMBER() OVER (PARTITION BY usr.cust_sk ORDER BY usr.amount DESC) AS rn_amount_desc,
  RANK() OVER (ORDER BY usr.amount DESC) AS global_amount_rank
FROM union_sales_returns usr
WHERE usr.trans_date_sk BETWEEN 2450815 AND 2451200
  AND usr.quantity > 0
  AND usr.amount > 0
  AND usr.t_hour BETWEEN 8 AND 18
  AND usr.cust_sk IN (SELECT customer_sk FROM exclusive_sales_cust)
ORDER BY usr.amount DESC
LIMIT 100
