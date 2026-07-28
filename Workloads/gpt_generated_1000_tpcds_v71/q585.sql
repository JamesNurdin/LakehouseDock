/*
Goal: Identify high‑value customers who returned catalog items, their associated warehouse and web page details, and rank them by total return amount while showing warehouse‑level cumulative returns.
*/
WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        hd_ref.hd_income_band_sk,
        hd_ref.hd_buy_potential,
        sr.sr_returned_date_sk AS sr_returned_date_sk,
        sr.sr_return_amt,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_country,
        w.w_street_type,
        wp.wp_type,
        wp.wp_url
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_store
        ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND w.w_country = 'United States'
      AND w.w_street_type = 'Street'
      AND cr.cr_return_amount > 1000
      AND cs.cs_coupon_amt > 50
),
aggregated AS (
    SELECT
        f.c_customer_sk,
        f.c_preferred_cust_flag,
        f.c_birth_year,
        f.w_warehouse_sk,
        f.w_warehouse_id,
        f.wp_type,
        SUM(f.cr_return_amount)                AS sum_return_amount,
        SUM(f.cs_ext_sales_price)               AS sum_sales_price,
        SUM(f.cs_net_profit)                    AS sum_net_profit,
        SUM(f.sr_return_amt)                    AS sum_store_return_amt,
        AVG(f.cs_coupon_amt)                    AS avg_coupon_amt,
        COUNT(*)                                 AS txn_count,
        (SELECT SUM(cr_sub.cr_return_amount)
           FROM catalog_returns cr_sub
          WHERE cr_sub.cr_warehouse_sk = f.w_warehouse_sk) AS warehouse_total_return
    FROM filtered f
    GROUP BY
        f.c_customer_sk,
        f.c_preferred_cust_flag,
        f.c_birth_year,
        f.w_warehouse_sk,
        f.w_warehouse_id,
        f.wp_type
)
SELECT
    a.c_customer_sk,
    a.c_preferred_cust_flag,
    a.c_birth_year,
    a.w_warehouse_id,
    a.wp_type,
    a.sum_return_amount,
    a.sum_sales_price,
    a.sum_net_profit,
    a.sum_store_return_amt,
    a.avg_coupon_amt,
    a.txn_count,
    a.warehouse_total_return,
    SUM(a.sum_return_amount) OVER (PARTITION BY a.w_warehouse_id ORDER BY a.sum_return_amount DESC) AS cum_return_by_warehouse,
    RANK() OVER (PARTITION BY a.w_warehouse_id ORDER BY a.sum_return_amount DESC) AS rank_within_warehouse
FROM aggregated a
WHERE a.sum_return_amount > 5000
ORDER BY a.w_warehouse_id, rank_within_warehouse
LIMIT 100
