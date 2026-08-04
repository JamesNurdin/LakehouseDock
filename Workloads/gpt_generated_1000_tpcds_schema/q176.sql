WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        d.d_year,
        d.d_month_seq,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_quantity)               AS total_quantity,
        SUM(cs.cs_ext_sales_price)        AS total_sales,
        SUM(cs.cs_net_profit)             AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY
        cs.cs_item_sk,
        d.d_year,
        d.d_month_seq,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_sold_time_sk
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        d.d_year,
        d.d_month_seq,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_sold_time_sk,
        SUM(ws.ws_quantity)               AS total_quantity,
        SUM(ws.ws_ext_sales_price)        AS total_sales,
        SUM(ws.ws_net_profit)             AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        ws.ws_item_sk,
        d.d_year,
        d.d_month_seq,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_sold_time_sk
),
full_joined AS (
    SELECT
        cs.cs_item_sk,
        ws.ws_item_sk,
        cs.d_year,
        cs.d_month_seq,
        cs.cs_catalog_page_sk,
        ws.ws_promo_sk          AS ws_promo_sk,
        cs.cs_promo_sk           AS cs_promo_sk,
        cs.cs_bill_customer_sk,
        ws.ws_bill_customer_sk   AS ws_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        ws.ws_bill_cdemo_sk      AS ws_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        ws.ws_bill_hdemo_sk      AS ws_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        ws.ws_bill_addr_sk       AS ws_bill_addr_sk,
        cs.cs_sold_time_sk,
        ws.ws_sold_time_sk       AS ws_sold_time_sk,
        cs.total_quantity        AS cs_total_quantity,
        ws.total_quantity        AS ws_total_quantity,
        cs.total_sales           AS cs_total_sales,
        ws.total_sales           AS ws_total_sales,
        cs.total_profit          AS cs_total_profit,
        ws.total_profit          AS ws_total_profit
    FROM cs_agg cs
    FULL OUTER JOIN ws_agg ws
        ON cs.cs_item_sk = ws.ws_item_sk
       AND cs.d_year    = ws.d_year
       AND cs.d_month_seq = ws.d_month_seq
)
SELECT
    i.i_item_id,
    i.i_product_name,
    fj.d_year,
    fj.d_month_seq,
    COALESCE(fj.cs_total_profit, 0) + COALESCE(fj.ws_total_profit, 0) AS combined_profit,
    ROW_NUMBER() OVER (PARTITION BY fj.d_year, fj.d_month_seq
                       ORDER BY COALESCE(fj.cs_total_profit, 0) + COALESCE(fj.ws_total_profit, 0) DESC) AS profit_rank,
    cp.cp_department,
    p1.p_promo_name      AS catalog_promo_name,
    p2.p_promo_name      AS web_promo_name,
    ca.ca_city,
    cd.cd_credit_rating,
    hd.hd_vehicle_count,
    t.t_hour
FROM full_joined fj
LEFT JOIN item i ON i.i_item_sk = COALESCE(fj.cs_item_sk, fj.ws_item_sk)
LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = fj.cs_catalog_page_sk
LEFT JOIN promotion p1 ON p1.p_promo_sk = fj.cs_promo_sk
LEFT JOIN promotion p2 ON p2.p_promo_sk = fj.ws_promo_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = COALESCE(fj.cs_bill_addr_sk, fj.ws_bill_addr_sk)
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = COALESCE(fj.cs_bill_cdemo_sk, fj.ws_bill_cdemo_sk)
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = COALESCE(fj.cs_bill_hdemo_sk, fj.ws_bill_hdemo_sk)
LEFT JOIN time_dim t ON t.t_time_sk = COALESCE(fj.cs_sold_time_sk, fj.ws_sold_time_sk)
WHERE
    fj.d_year IN (2020, 2021)
    AND i.i_brand = 'BrandX'
    AND p1.p_discount_active = 'Y'
    AND cd.cd_credit_rating = 'Good'
    AND hd.hd_vehicle_count > 0
ORDER BY combined_profit DESC
LIMIT 100
