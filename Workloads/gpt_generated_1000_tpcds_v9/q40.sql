WITH sales_no_return AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        p.p_promo_name,
        p.p_discount_active,
        cc.cc_name,
        cd.cd_gender
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{2}$')
      AND cc.cc_name LIKE 'Call Center%'
      AND cd.cd_gender = 'M'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
)
SELECT
    t.t_hour,
    t.t_am_pm,
    substring(snr.cc_name FROM 1 FOR 10) AS cc_name_prefix,
    snr.p_promo_name,
    CASE
        WHEN snr.p_discount_active = 'Y' THEN 'Discounted'
        ELSE 'Standard'
    END AS promo_type,
    COUNT(*) AS sales_cnt,
    SUM(snr.cs_ext_sales_price) AS total_sales,
    SUM(CASE WHEN snr.cs_quantity > 5 THEN snr.cs_ext_sales_price ELSE 0 END) AS high_qty_sales
FROM sales_no_return snr
RIGHT OUTER JOIN time_dim t
    ON snr.cs_sold_time_sk = t.t_time_sk
GROUP BY
    t.t_hour,
    t.t_am_pm,
    substring(snr.cc_name FROM 1 FOR 10),
    snr.p_promo_name,
    CASE
        WHEN snr.p_discount_active = 'Y' THEN 'Discounted'
        ELSE 'Standard'
    END
ORDER BY total_sales DESC
LIMIT 100
