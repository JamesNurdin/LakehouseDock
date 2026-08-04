WITH catalog_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_wholesale_cost,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        i.i_category,
        i.i_brand,
        p.p_channel_catalog,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_wholesale_cost > 60
      AND cs.cs_ext_discount_amt BETWEEN 1000 AND 4000
      AND p.p_discount_active = 'Y'
),
store_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_category AS ss_category,
        i.i_brand AS ss_brand,
        p.p_channel_catalog AS ss_channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_sales_price > 1000
),
aggregated AS (
    SELECT
        cb.i_category,
        cb.i_brand,
        cb.p_channel_catalog,
        COUNT(DISTINCT cb.cs_order_number) AS catalog_orders,
        SUM(cb.cs_ext_sales_price) AS catalog_sales_total,
        SUM(cb.cs_net_profit) AS catalog_profit_total,
        COUNT(DISTINCT sb.ss_ticket_number) AS store_tickets,
        SUM(sb.ss_ext_sales_price) AS store_sales_total,
        SUM(sb.ss_net_profit) AS store_profit_total,
        CASE
            WHEN SUM(cb.cs_ext_sales_price) > SUM(sb.ss_ext_sales_price) THEN 'Catalog Higher'
            ELSE 'Store Higher'
        END AS higher_sales_channel,
        (
            SELECT COUNT(*)
            FROM promotion p2
            WHERE p2.p_channel_catalog = cb.p_channel_catalog
              AND p2.p_cost > 500
        ) AS promo_count_high_cost
    FROM catalog_base cb
    JOIN store_base sb
      ON cb.cs_item_sk = sb.ss_item_sk
     AND cb.cs_promo_sk = sb.ss_promo_sk
    JOIN call_center cc
      ON cb.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cb.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cb.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_catalog_page_number IN (1, 5, 15)
      AND sm.sm_code = 'AIR       '
      AND cc.cc_state = 'CA'
    GROUP BY cb.i_category, cb.i_brand, cb.p_channel_catalog
    HAVING COUNT(DISTINCT cb.cs_order_number) > 5
)
SELECT *
FROM aggregated
EXCEPT
SELECT
    i_category,
    i_brand,
    p_channel_catalog,
    CAST(0 AS BIGINT) AS catalog_orders,
    CAST(0.0 AS DOUBLE) AS catalog_sales_total,
    CAST(0.0 AS DOUBLE) AS catalog_profit_total,
    CAST(0 AS BIGINT) AS store_tickets,
    CAST(0.0 AS DOUBLE) AS store_sales_total,
    CAST(0.0 AS DOUBLE) AS store_profit_total,
    CAST(NULL AS VARCHAR) AS higher_sales_channel,
    CAST(0 AS BIGINT) AS promo_count_high_cost
FROM (
    SELECT
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        p.p_channel_catalog AS p_channel_catalog
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
) promo_dim
LIMIT 100
