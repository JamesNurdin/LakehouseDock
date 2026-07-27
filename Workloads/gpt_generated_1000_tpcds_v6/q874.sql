WITH sales_details AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_catalog_page_sk,
        cp.cp_catalog_page_number,
        cp.cp_end_date_sk,
        p.p_promo_id,
        p.p_response_target,
        p.p_channel_press,
        td.t_hour,
        td.t_minute,
        td.t_second,
        CASE
            WHEN cs.cs_net_profit > 0 THEN 'POSITIVE'
            WHEN cs.cs_net_profit = 0 THEN 'ZERO'
            ELSE 'NEGATIVE'
        END AS profit_flag,
        (
            SELECT max(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_promo_sk = cs.cs_promo_sk
        ) AS max_sales_price_for_promo
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE p.p_response_target = 1
      AND p.p_channel_press = 'N'
)
SELECT
    p_promo_id,
    profit_flag,
    max_sales_price_for_promo,
    total_quantity,
    total_sales,
    total_profit
FROM (
    SELECT
        p_promo_id,
        profit_flag,
        max_sales_price_for_promo,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM sales_details
    WHERE cp_catalog_page_number BETWEEN 1 AND 10
      AND t_minute < 12
    GROUP BY p_promo_id, profit_flag, max_sales_price_for_promo

    UNION ALL

    SELECT
        p_promo_id,
        profit_flag,
        max_sales_price_for_promo,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM sales_details sd
    WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp3
        WHERE cp3.cp_catalog_page_sk = sd.cs_catalog_page_sk
          AND cp3.cp_end_date_sk BETWEEN 2450904 AND 2451114
    )
    GROUP BY p_promo_id, profit_flag, max_sales_price_for_promo
) combined
ORDER BY p_promo_id, profit_flag
