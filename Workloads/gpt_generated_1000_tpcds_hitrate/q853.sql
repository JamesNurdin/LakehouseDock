WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    WHERE cs_sold_date_sk BETWEEN 2451545 AND 2451910        -- realistic surrogate date range
      AND cs_quantity > 5
      AND cs_sales_price > 100
      AND cs_net_profit > 0
),
web_sales_filtered AS (
    SELECT ws_bill_customer_sk, ws_sold_date_sk, ws_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ws_quantity > 3
      AND ws_sales_price > 150
      AND ws_net_profit > 0
),
common_customers AS (
    SELECT c_customer_sk
    FROM (
        SELECT cs_bill_customer_sk AS c_customer_sk FROM cs_sample
        INTERSECT
        SELECT ws_bill_customer_sk FROM web_sales_filtered
    ) AS inter
)
SELECT
    d.d_year,
    i.i_category,
    p.p_promo_name,
    ch.channel,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(cs.cs_ext_sales_price) AS min_sale,
    MAX(cs.cs_ext_sales_price) AS max_sale
FROM cs_sample cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                 AND inv.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
RIGHT OUTER JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN common_customers ccust ON c.c_customer_sk = ccust.c_customer_sk
LEFT JOIN LATERAL (
    SELECT channel
    FROM UNNEST(ARRAY[p.p_channel_email, p.p_channel_tv]) AS t(channel)
) AS ch ON true
WHERE cd.cd_gender = 'M'
  AND p.p_channel_email = 'Y'
  AND cc.cc_state = 'CA'
  AND i.i_color = 'RED'
GROUP BY d.d_year, i.i_category, p.p_promo_name, ch.channel
ORDER BY total_sales DESC
LIMIT 100
