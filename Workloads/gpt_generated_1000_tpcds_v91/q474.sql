WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_category_id,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'profitable' ELSE 'loss' END AS profit_status,
        MAX(ws.ws_ext_sales_price) AS max_item_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE
        td.t_sub_shift = 'morning'
        AND td.t_minute >= 10
        AND i.i_category_id IN (2, 6, 8, 10)
        AND ws_site.web_class = 'Unknown'
        AND cd_bill.cd_gender = 'F'
        AND p.p_discount_active = 'N'
        AND i.i_rec_start_date >= DATE '2000-01-01'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_category_id,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk
),
brand_sales AS (
    SELECT
        is1.i_brand,
        is1.i_category,
        is1.ws_web_site_sk,
        SUM(is1.total_sales) AS brand_category_sales,
        SUM(is1.total_profit) AS brand_category_profit,
        COUNT(DISTINCT is1.i_item_sk) AS distinct_items,
        CASE WHEN SUM(is1.total_profit) > 0 THEN 'profitable' ELSE 'loss' END AS brand_profit_status
    FROM item_sales is1
    -- anti‑join: exclude items that have any active discount promotion
    WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = is1.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
    GROUP BY
        is1.i_brand,
        is1.i_category,
        is1.ws_web_site_sk
    HAVING SUM(is1.total_sales) > 1000
)
SELECT
    bs.i_brand,
    bs.i_category,
    ws.web_name,
    bs.brand_category_sales,
    bs.brand_category_profit,
    bs.brand_profit_status,
    bs.distinct_items,
    (
        SELECT MAX(is2.total_sales)
        FROM item_sales is2
        WHERE is2.i_brand = bs.i_brand
    ) AS max_item_sales_in_brand,
    SUM(bs.brand_category_sales) OVER (
        PARTITION BY bs.i_brand
        ORDER BY bs.brand_category_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_brand_sales
FROM brand_sales bs
JOIN web_site ws ON bs.ws_web_site_sk = ws.web_site_sk
WHERE bs.brand_category_sales > 5000
ORDER BY bs.i_brand, running_brand_sales DESC
