WITH
store_promo_items AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        i.i_category,
        i.i_current_price,
        p.p_promo_name,
        s.s_store_name,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ca.ca_state,
        i2.i_brand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i2 ON p.p_item_sk = i2.i_item_sk
    WHERE p.p_discount_active = 'Y'
),
web_promo_items AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        i.i_category AS web_category,
        i.i_current_price AS web_price,
        p.p_promo_name AS web_promo_name,
        ca_bill.ca_city AS billing_city,
        ca_ship.ca_city AS shipping_city,
        ws.ws_ext_sales_price,
        ws.ws_ext_wholesale_cost,
        i2.i_brand AS promo_item_brand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN item i2 ON p.p_item_sk = i2.i_item_sk
    WHERE p.p_discount_active = 'Y'
),
aggregated AS (
    SELECT
        spi.ss_sold_date_sk AS sold_date_sk,
        spi.i_category,
        spi.s_store_name,
        spi.p_promo_name,
        SUM(spi.ss_ext_sales_price) AS store_sales_total,
        SUM(spi.ss_ext_wholesale_cost) AS store_wholesale_total,
        SUM(wpi.ws_ext_sales_price) AS web_sales_total,
        SUM(wpi.ws_ext_wholesale_cost) AS web_wholesale_total
    FROM store_promo_items spi
    LEFT JOIN web_promo_items wpi
        ON spi.ss_item_sk = wpi.ws_item_sk
        AND spi.ss_sold_date_sk = wpi.ws_sold_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p_check
        WHERE p_check.p_promo_sk = spi.ss_promo_sk
          AND p_check.p_channel_email = 'N'
    )
    GROUP BY
        spi.ss_sold_date_sk,
        spi.i_category,
        spi.s_store_name,
        spi.p_promo_name
),
to_exclude AS (
    SELECT
        spi.ss_sold_date_sk AS sold_date_sk,
        spi.i_category,
        spi.s_store_name,
        spi.p_promo_name,
        SUM(spi.ss_ext_sales_price) AS store_sales_total,
        SUM(spi.ss_ext_wholesale_cost) AS store_wholesale_total,
        0.0 AS web_sales_total,
        0.0 AS web_wholesale_total
    FROM store_promo_items spi
    GROUP BY
        spi.ss_sold_date_sk,
        spi.i_category,
        spi.s_store_name,
        spi.p_promo_name
)
SELECT
    final.*, 
    ROW_NUMBER() OVER (ORDER BY final.store_sales_total DESC) AS rn
FROM (
    SELECT
        a.sold_date_sk,
        a.i_category,
        a.s_store_name,
        a.p_promo_name,
        a.store_sales_total,
        a.web_sales_total
    FROM aggregated a
    EXCEPT
    SELECT
        e.sold_date_sk,
        e.i_category,
        e.s_store_name,
        e.p_promo_name,
        e.store_sales_total,
        e.web_sales_total
    FROM to_exclude e
) final
ORDER BY final.store_sales_total DESC
LIMIT 100
