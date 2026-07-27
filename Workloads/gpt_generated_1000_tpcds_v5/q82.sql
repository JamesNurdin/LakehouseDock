/*
Goal: Rank promotional sales from catalog and store channels, filtering to high‑cost promotions, customers with good credit rating, and business‑hour transactions, while ensuring a matching high‑value web sale exists. Sales are categorized as High or Low and the top 100 rows are returned.
*/
WITH sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        td.t_time_sk      AS sold_time_sk,
        td.t_hour,
        p.p_promo_sk,
        p.p_promo_id,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_cost > 500
      AND cd.cd_credit_rating = 'Good'
      AND td.t_hour BETWEEN 9 AND 17

    UNION ALL

    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        td.t_time_sk      AS sold_time_sk,
        td.t_hour,
        p.p_promo_sk,
        p.p_promo_id,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_cost > 500
      AND cd.cd_credit_rating = 'Good'
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    su.sold_date_sk,
    su.t_hour,
    su.p_promo_id,
    su.sales_amount,
    CASE WHEN su.sales_amount > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY su.p_promo_id ORDER BY su.sales_amount DESC) AS rn
FROM sales_union su
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    WHERE ws.ws_ext_sales_price > 2000
      AND p2.p_promo_sk = su.p_promo_sk
      AND td2.t_time_sk = su.sold_time_sk
)
ORDER BY rn, su.sales_amount DESC
LIMIT 100
