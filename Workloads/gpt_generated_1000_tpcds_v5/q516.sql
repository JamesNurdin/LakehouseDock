WITH base AS (
    SELECT
        cc.cc_name,
        p.p_promo_name,
        ca.ca_street_number,
        cs.cs_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cc.cc_name, 'Center')
      AND ca.ca_street_type LIKE 'St%'
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        cc_name,
        p_promo_name,
        regexp_extract(ca_street_number, '\\d+') AS street_num_digits,
        sum(cs_net_paid) AS total_net_paid,
        count(*) AS sales_cnt
    FROM base
    GROUP BY
        cc_name,
        p_promo_name,
        regexp_extract(ca_street_number, '\\d+')
    HAVING sum(cs_net_paid) > 1000
)
SELECT
    cc_name,
    p_promo_name,
    street_num_digits,
    total_net_paid,
    sales_cnt,
    row_number() OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC) AS rn
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
