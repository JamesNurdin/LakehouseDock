SELECT
    d.d_year AS year,
    s.s_store_name AS store_name,
    i.i_category AS category,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
FROM
    store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE
    d.d_year BETWEEN 2000 AND 2002
GROUP BY
    d.d_year,
    s.s_store_name,
    i.i_category
ORDER BY
    d.d_year,
    s.s_store_name,
    i.i_category
LIMIT 100
