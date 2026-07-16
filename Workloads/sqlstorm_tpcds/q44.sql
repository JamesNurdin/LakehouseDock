WITH sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           NULL AS store_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           NULL,
           'web'
    FROM web_sales ws
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_store_sk,
           'store'
    FROM store_sales ss
),
customer_last_sale AS (
    SELECT s.customer_sk,
           MAX(d.d_date) AS last_sale_date
    FROM sales_union s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    GROUP BY s.customer_sk
),
sales_with_details AS (
    SELECT
        s.sold_date_sk,
        d.d_date AS sale_date,
        d.d_year,
        d.d_month_seq,
        s.item_sk,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        s.customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        c.c_preferred_cust_flag,
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
        cd.cd_gender,
        COALESCE(ca.ca_city, 'UNKNOWN') AS city,
        ca.ca_state,
        s.quantity,
        s.net_paid,
        s.net_profit,
        s.channel,
        s.store_sk,
        st.s_store_name,
        st.s_state AS store_state,
        cls.last_sale_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_sk ORDER BY d.d_date DESC) AS rn,
        RANK() OVER (PARTITION BY s.channel ORDER BY s.net_profit DESC) AS profit_rank,
        SUM(s.net_paid) OVER (PARTITION BY s.channel) AS total_channel_net_paid,
        AVG(s.net_profit) OVER (PARTITION BY d.d_year) AS avg_yearly_profit,
        CASE WHEN s.net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        CASE WHEN cd.cd_gender IS NULL THEN 'UNKNOWN' ELSE cd.cd_gender END AS gender_filled,
        substring(i.i_category, 1, 3) AS cat_prefix,
        REGEXP_REPLACE(COALESCE(ca.ca_city, ''), '[^A-Za-z]', '') AS city_alpha,
        (s.quantity * s.net_paid) AS weighted_sales,
        ROUND(s.net_profit / NULLIF(s.net_paid, 0), 2) AS profit_margin
    FROM sales_union s
    LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store st ON s.channel = 'store' AND s.store_sk = st.s_store_sk
    LEFT JOIN customer_last_sale cls ON s.customer_sk = cls.customer_sk
)
SELECT
    swd.full_name,
    swd.cust_type,
    swd.city,
    swd.city_alpha,
    swd.i_category,
    swd.cat_prefix,
    swd.i_brand,
    swd.channel,
    swd.d_year,
    swd.d_month_seq,
    swd.sale_date,
    swd.quantity,
    swd.net_paid,
    swd.net_profit,
    swd.profit_margin,
    swd.profit_flag,
    swd.profit_rank,
    swd.total_channel_net_paid,
    swd.avg_yearly_profit,
    swd.rn,
    CASE WHEN swd.rn = 1 THEN 'Most Recent' ELSE 'Older' END AS sale_recency,
    swd.last_sale_date,
    (SELECT SUM(s2.net_paid)
     FROM sales_union s2
     JOIN date_dim d2 ON s2.sold_date_sk = d2.d_date_sk
     WHERE s2.customer_sk = swd.customer_sk
       AND d2.d_date BETWEEN date_add('day', -30, swd.sale_date) AND date_add('day', 30, swd.sale_date)
    ) AS rolling_30d_net_paid,
    swd.weighted_sales,
    swd.name_length,
    swd.gender_filled,
    COALESCE(swd.s_store_name, 'NO STORE') AS store_name,
    COALESCE(swd.store_state, 'NO STATE') AS store_state
FROM sales_with_details swd
WHERE swd.d_year >= 2000
  AND swd.net_paid > 0
  AND (swd.city IS NOT NULL AND swd.city <> 'UNKNOWN')
  AND (swd.i_category = 'Sports' OR swd.i_brand = 'Brand#12')
  AND (swd.channel = 'store' OR swd.channel = 'web')
ORDER BY swd.net_profit DESC NULLS LAST
LIMIT 100
