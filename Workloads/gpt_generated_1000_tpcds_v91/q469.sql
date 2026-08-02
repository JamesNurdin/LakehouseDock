WITH
cs_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk AS cs_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price AS amount,
        cs.cs_bill_customer_sk AS customer_sk,
        cd.cd_demo_sk,
        hd.hd_demo_sk,
        p.p_promo_id,
        cc.cc_name,
        cc.cc_mkt_id,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        ib.ib_upper_bound,
        cs.cs_warehouse_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_year = 2001
        AND cs.cs_quantity > 2
        AND p.p_discount_active = 'Y'
        AND ib.ib_upper_bound > 50000
        AND cc.cc_mkt_id = 3
        AND sm.sm_type = 'AIR'
),
inventory_base AS (
    SELECT
        i.inv_date_sk AS inv_date_sk,
        i.inv_item_sk AS item_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        d.d_year AS inv_year
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
),
ss_base AS (
    SELECT
        ss.ss_sold_date_sk AS ss_date_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price AS amount,
        cd.cd_demo_sk,
        hd.hd_demo_sk,
        p.p_promo_id,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
        AND ss.ss_quantity > 5
        AND p.p_discount_active = 'Y'
),
sr_base AS (
    SELECT
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt AS amount,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
        AND sr.sr_return_amt > 50
),
wr_base AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_return_amt AS amount,
        wp.wp_type,
        d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer cust ON wp.wp_customer_sk = cust.c_customer_sk
    WHERE d.d_year = 2001
        AND wr.wr_return_amt > 100
        AND wp.wp_type = 'product'
),
union_data AS (
    SELECT DISTINCT
        ss.customer_sk,
        ss.ss_date_sk AS date_sk,
        ss.amount,
        'store_sales' AS source
    FROM ss_base ss
    UNION ALL
    SELECT DISTINCT
        sr.customer_sk,
        sr.return_date_sk AS date_sk,
        sr.amount,
        'store_returns' AS source
    FROM sr_base sr
    UNION ALL
    SELECT DISTINCT
        wr.customer_sk,
        wr.return_date_sk AS date_sk,
        wr.amount,
        'web_returns' AS source
    FROM wr_base wr
),
full_joined AS (
    SELECT
        cs.customer_sk,
        cs.cs_date_sk AS date_sk,
        cs.amount,
        cs.cc_name,
        cs.cc_mkt_id,
        cs.sm_ship_mode_id,
        cs.w_warehouse_name,
        cs.ib_upper_bound,
        ib.inv_quantity_on_hand,
        ib.inv_date_sk
    FROM cs_base cs
    FULL OUTER JOIN inventory_base ib
        ON cs.cs_warehouse_sk = ib.w_warehouse_sk
       AND cs.item_sk = ib.item_sk
)
SELECT
    ud.customer_sk,
    ud.date_sk,
    ud.amount,
    ud.source,
    fj.cc_name,
    fj.w_warehouse_name,
    fj.ib_upper_bound,
    fj.inv_quantity_on_hand,
    ROW_NUMBER() OVER (ORDER BY ud.amount DESC) AS rn_global,
    DENSE_RANK() OVER (PARTITION BY ud.source ORDER BY ud.amount DESC) AS rank_in_source,
    (SELECT SUM(cs2.amount)
       FROM cs_base cs2
      WHERE cs2.customer_sk = ud.customer_sk) AS total_amount_by_customer,
    CASE WHEN ud.amount >= 500 THEN 'HIGH' ELSE 'LOW' END AS amount_category
FROM union_data ud
FULL OUTER JOIN full_joined fj
    ON ud.customer_sk = fj.customer_sk
   AND ud.date_sk = fj.date_sk
WHERE EXISTS (
        SELECT 1
          FROM store_sales ss2
         WHERE ss2.ss_customer_sk = ud.customer_sk
           AND ss2.ss_quantity > 10
      )
  AND ud.amount > 0
ORDER BY rn_global
OFFSET 0
LIMIT 100
