WITH sampled_cs AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_date_sk,
        cs_bill_customer_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_customer_sk,
        cs_ship_cdemo_sk,
        cs_ship_hdemo_sk,
        cs_ship_addr_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_order_number,
        cs_quantity,
        cs_wholesale_cost,
        cs_list_price,
        cs_sales_price,
        cs_ext_discount_amt,
        cs_ext_sales_price,
        cs_ext_wholesale_cost,
        cs_ext_list_price,
        cs_ext_tax,
        cs_coupon_amt,
        cs_ext_ship_cost,
        cs_net_paid,
        cs_net_paid_inc_tax,
        cs_net_paid_inc_ship,
        cs_net_paid_inc_ship_tax,
        cs_net_profit
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_coupon_amt > 1000
),
promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
        SUM(
            (SELECT COUNT(*)
             FROM store_sales ss2
             WHERE ss2.ss_customer_sk = cs.cs_bill_customer_sk
               AND ss2.ss_sold_date_sk < cs.cs_sold_date_sk)
        ) AS total_prior_store_sales
    FROM call_center cc
    JOIN sampled_cs cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_company_name = 'able'
      AND p.p_channel_email = 'N'
      AND d.d_year = 2001
    GROUP BY p.p_promo_id, p.p_promo_name, d.d_year
)
SELECT
    p_promo_id,
    p_promo_name,
    d_year,
    total_catalog_sales,
    total_store_sales,
    num_call_centers,
    CASE WHEN total_discount_amount > 10000 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category,
    total_prior_store_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS promo_sales_rank
FROM promo_agg
ORDER BY d_year, promo_sales_rank
