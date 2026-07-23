WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_order_number,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_details,
        cc.cc_name,
        cc.cc_city,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        d.d_year
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE
        cc.cc_city LIKE 'A%'
        AND regexp_like(p.p_channel_details, '(?i)structures')
        AND c.c_email_address LIKE '%.com'
        AND d.d_year = 2001
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    substring(p.p_promo_name, 1, 10) AS promo_name_prefix,
    cc.cc_name,
    cc.cc_city,
    sum(fs.cs_net_profit) AS total_net_profit,
    count(*) AS sales_count,
    max(c.c_email_address) AS max_email,
    regexp_extract(max(c.c_email_address), '@(.+)$') AS email_domain_sample,
    CASE WHEN sum(fs.cs_net_profit) > (
        SELECT avg(cs2.cs_net_profit)
        FROM tpcds.catalog_sales cs2
    ) THEN true ELSE false END AS above_avg_profit
FROM filtered_sales fs
JOIN tpcds.promotion p
    ON fs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.call_center cc
    ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.customer c
    ON fs.cs_bill_customer_sk = c.c_customer_sk
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    substring(p.p_promo_name, 1, 10),
    cc.cc_name,
    cc.cc_city
ORDER BY total_net_profit DESC
LIMIT 100
