WITH catalog_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(cs.cs_ext_discount_amt) AS cat_discount,
        COUNT(*) AS cat_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND d.d_year BETWEEN 2022 AND 2023
      AND (p.p_discount_active = 'Y' OR p.p_promo_sk IS NULL)
    GROUP BY i.i_category, i.i_brand, d.d_year
),
web_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND d.d_year BETWEEN 2022 AND 2023
      AND (p.p_discount_active = 'Y' OR p.p_promo_sk IS NULL)
    GROUP BY i.i_category, i.i_brand, d.d_year
)
SELECT
    ca.i_category,
    ca.i_brand,
    ca.d_year,
    ca.cat_net_profit + wa.web_net_profit AS total_net_profit,
    ca.cat_sales + wa.web_sales AS total_sales,
    (ca.cat_discount + wa.web_discount) / NULLIF(ca.cat_sales + wa.web_sales, 0) AS avg_discount_rate,
    ca.cat_orders + wa.web_orders AS total_orders,
    RANK() OVER (PARTITION BY ca.d_year ORDER BY ca.cat_net_profit + wa.web_net_profit DESC) AS profit_rank
FROM catalog_agg ca
JOIN web_agg wa
  ON ca.i_category = wa.i_category
 AND ca.i_brand = wa.i_brand
 AND ca.d_year = wa.d_year
ORDER BY ca.d_year, profit_rank
LIMIT 20
