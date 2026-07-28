WITH base AS (
    SELECT
        cp.cp_department,
        i.i_brand,
        ws.ws_net_paid          AS sales_amount,
        cr.cr_return_amount     AS return_amount,
        ws.ws_net_profit        AS profit_amount,
        ws.ws_order_number      AS order_number
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999                              -- filter 1: sold date range
      AND i.i_current_price > 20.00                                                   -- filter 2: price threshold
      AND p.p_channel_event = 'N'                                                     -- filter 3: promotion channel
      AND cp.cp_catalog_page_number IN (2, 5, 8)                                      -- filter 4: catalog page numbers
      AND cr.cr_return_amount > 100.00                                                -- filter 5: return amount threshold
      AND p.p_discount_active = 'Y'                                                   -- filter 6: active discount flag
),
aggregated AS (
    SELECT
        cp_department,
        i_brand,
        SUM(sales_amount)   AS total_sales,
        SUM(return_amount)  AS total_returns,
        SUM(profit_amount)  AS total_profit,
        COUNT(DISTINCT order_number) AS distinct_orders
    FROM base
    GROUP BY GROUPING SETS (
        (cp_department, i_brand),
        (cp_department),
        (i_brand),
        ()
    )
)
SELECT
    cp_department,
    i_brand,
    total_sales,
    total_returns,
    total_profit,
    distinct_orders
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
