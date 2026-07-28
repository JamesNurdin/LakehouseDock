WITH distinct_brands AS (
    SELECT DISTINCT i.i_brand, i.i_item_sk
    FROM item i
    WHERE i.i_brand IN ('Brand#12', 'Brand#23')
),
base AS (
    SELECT
        d.d_year,
        cc.cc_name,
        i.i_brand,
        cs.cs_net_paid_inc_tax,
        ss.ss_net_paid_inc_tax,
        sr.sr_return_amt_inc_tax,
        wr.wr_return_amt_inc_tax,
        cu.c_customer_id,
        r.r_reason_desc,
        p.p_discount_active
    FROM date_dim d
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
                           AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN distinct_brands db ON db.i_item_sk = cs.cs_item_sk
    JOIN item i ON i.i_item_sk = db.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
                      AND p.p_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                         AND ss.ss_customer_sk = cu.c_customer_sk
                         AND ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                           AND sr.sr_item_sk = i.i_item_sk
                           AND sr.sr_customer_sk = cu.c_customer_sk
                           AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_refunded_customer_sk = cu.c_customer_sk
                         AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    WHERE d.d_weekend = 'N'
)
SELECT *
FROM (
    SELECT
        d_year,
        cc_name,
        i_brand,
        SUM(cs_net_paid_inc_tax)               AS total_catalog_sales,
        SUM(ss_net_paid_inc_tax)               AS total_store_sales,
        SUM(sr_return_amt_inc_tax)             AS total_store_returns,
        SUM(wr_return_amt_inc_tax)             AS total_web_returns,
        COUNT(DISTINCT c_customer_id)          AS distinct_customers
    FROM base
    WHERE d_year = 1998
      AND cc_name = 'Call Center 1'
      AND i_brand = 'Brand#12'
      AND p_discount_active = 'Y'
      AND r_reason_desc = 'Customer Not Satisfied'
      AND cs_net_paid_inc_tax > 1000
    GROUP BY d_year, cc_name, i_brand

    UNION ALL

    SELECT
        d_year,
        cc_name,
        i_brand,
        SUM(cs_net_paid_inc_tax)               AS total_catalog_sales,
        SUM(ss_net_paid_inc_tax)               AS total_store_sales,
        SUM(sr_return_amt_inc_tax)             AS total_store_returns,
        SUM(wr_return_amt_inc_tax)             AS total_web_returns,
        COUNT(DISTINCT c_customer_id)          AS distinct_customers
    FROM base
    WHERE d_year = 1999
      AND cc_name = 'Call Center 2'
      AND i_brand = 'Brand#23'
      AND p_discount_active = 'N'
      AND r_reason_desc = 'Product Defective'
      AND cs_net_paid_inc_tax > 2000
    GROUP BY d_year, cc_name, i_brand
) AS combined
ORDER BY total_catalog_sales DESC
LIMIT 100
