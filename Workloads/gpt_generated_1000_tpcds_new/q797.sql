WITH sales_promo AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_bill_addr_sk,
        cs.cs_promo_sk,
        ca.ca_city,
        ca.ca_state,
        p.p_promo_name,
        t.t_sub_shift,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS location,
        SUBSTRING(ca.ca_city, 1, 3) AS city_prefix,
        REGEXP_EXTRACT(p.p_promo_name, '([A-Za-z]+) Discount', 1) AS discount_type,
        CASE
            WHEN cs.cs_net_profit > 0 THEN 'Profitable'
            WHEN cs.cs_net_profit = 0 THEN 'BreakEven'
            ELSE 'Loss'
        END AS profit_category
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount')
      AND ca.ca_city LIKE 'A%'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
          WHERE t2.t_time_sk = cs.cs_sold_time_sk
            AND wr.wr_return_amt > 0
      )
)
SELECT
    sp.p_promo_name,
    sp.discount_type,
    sp.profit_category,
    sp.t_sub_shift,
    sp.location,
    sp.city_prefix,
    COUNT(DISTINCT sp.cs_order_number) AS orders,
    SUM(sp.cs_ext_sales_price) AS total_sales,
    SUM(sp.cs_net_profit) AS total_profit,
    (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        WHERE sr.sr_addr_sk = sp.cs_bill_addr_sk
    ) AS total_return_amt_for_address,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
        WHERE t2.t_time_sk = sp.cs_sold_time_sk
    ) AS web_return_count
FROM sales_promo sp
GROUP BY
    sp.p_promo_name,
    sp.discount_type,
    sp.profit_category,
    sp.t_sub_shift,
    sp.location,
    sp.city_prefix,
    sp.cs_bill_addr_sk,
    sp.cs_sold_time_sk
HAVING SUM(sp.cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
