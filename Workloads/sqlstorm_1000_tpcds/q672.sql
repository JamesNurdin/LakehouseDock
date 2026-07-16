WITH sales_by_channel AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_order_number AS order_no,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS profit,
        'catalog' AS channel,
        cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    UNION ALL
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        'store',
        NULL
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    UNION ALL
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        'web',
        NULL
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
),
item_sales AS (
    SELECT
        sbc.item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_color,
        i.i_size,
        SUM(sbc.quantity) AS total_quantity,
        SUM(sbc.profit) AS total_profit,
        COUNT(DISTINCT sbc.date_sk) AS active_days,
        MIN(sbc.date_sk) AS first_sold_date_sk,
        MAX(sbc.date_sk) AS last_sold_date_sk,
        COUNT(DISTINCT sbc.channel) AS channel_count,
        COALESCE(SUM(CASE WHEN sbc.channel = 'catalog' THEN sbc.profit END), 0) AS catalog_profit,
        COALESCE(SUM(CASE WHEN sbc.channel = 'store' THEN sbc.profit END), 0) AS store_profit,
        COALESCE(SUM(CASE WHEN sbc.channel = 'web' THEN sbc.profit END), 0) AS web_profit
    FROM sales_by_channel sbc
    LEFT JOIN item i ON sbc.item_sk = i.i_item_sk
    GROUP BY sbc.item_sk, i.i_product_name, i.i_category, i.i_brand, i.i_color, i.i_size
),
inventory_snapshot AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk,
        ROW_NUMBER() OVER (PARTITION BY inv.inv_item_sk ORDER BY inv.inv_date_sk DESC) AS rn
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand IS NOT NULL
),
latest_inventory AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk
    FROM inventory_snapshot inv
    WHERE inv.rn = 1
),
returns_aggregated AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
    UNION ALL
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity),
        SUM(sr.sr_net_loss)
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
    UNION ALL
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity),
        SUM(wr.wr_net_loss)
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
returns_combined AS (
    SELECT
        r.item_sk,
        SUM(r.total_return_qty) AS total_return_qty,
        SUM(r.total_return_loss) AS total_return_loss
    FROM returns_aggregated r
    GROUP BY r.item_sk
),
final_report AS (
    SELECT
        isd.item_sk,
        isd.i_product_name,
        isd.i_category,
        isd.i_brand,
        isd.total_quantity,
        isd.total_profit,
        isd.active_days,
        CASE
            WHEN isd.total_profit > 0 THEN 'PROFITABLE'
            WHEN isd.total_profit < 0 THEN 'UNPROFITABLE'
            ELSE 'NEUTRAL'
        END AS profit_status,
        COALESCE(linv.inv_quantity_on_hand, 0) AS latest_inventory_qty,
        COALESCE(rt.total_return_qty, 0) AS total_returns,
        COALESCE(rt.total_return_loss, 0) AS return_loss,
        (isd.total_profit - COALESCE(rt.total_return_loss, 0)) AS net_profit_after_returns,
        ROW_NUMBER() OVER (ORDER BY (isd.total_profit - COALESCE(rt.total_return_loss, 0)) DESC) AS profit_rank,
        CONCAT(
            'Item ', LPAD(CAST(isd.item_sk AS VARCHAR), 8, '0'), ': ',
            COALESCE(isd.i_product_name, 'UNKNOWN')
        ) AS item_display,
        (SELECT MAX(d.d_date)
         FROM date_dim d
         WHERE d.d_date_sk = isd.last_sold_date_sk) AS last_sale_date,
        CASE
            WHEN isd.i_color IS NOT NULL AND REGEXP_LIKE(isd.i_color, '^R.*') THEN 'Redish'
            WHEN isd.i_size IS NULL THEN 'SizeMissing'
            ELSE 'OtherColorOrSize'
        END AS color_size_category,
        SUM(CASE WHEN isd.channel_count = 3 THEN isd.total_quantity ELSE 0 END) OVER () AS total_qty_all_channels
    FROM item_sales isd
    LEFT JOIN latest_inventory linv ON isd.item_sk = linv.inv_item_sk
    LEFT JOIN returns_combined rt ON isd.item_sk = rt.item_sk
    LEFT JOIN call_center cc ON isd.channel_count > 0 AND cc.cc_call_center_sk = mod(isd.item_sk, 10000)
    WHERE
        (isd.total_quantity > 0 OR isd.total_quantity IS NULL)
        AND (isd.i_category IS NOT NULL OR isd.i_brand IS NOT NULL)
        AND NOT (isd.i_brand = 'UNKNOWN' AND isd.i_category = 'UNKNOWN')
        AND (isd.i_product_name IS NOT NULL OR LENGTH(isd.i_product_name) = 0)
        AND (isd.i_product_name LIKE '%' || COALESCE('A','') || '%' ESCAPE '\\')
    GROUP BY
        isd.item_sk,
        isd.i_product_name,
        isd.i_category,
        isd.i_brand,
        isd.total_quantity,
        isd.total_profit,
        isd.active_days,
        isd.channel_count,
        isd.last_sold_date_sk,
        isd.i_color,
        isd.i_size,
        linv.inv_quantity_on_hand,
        rt.total_return_qty,
        rt.total_return_loss
)
SELECT
    fr.item_sk,
    fr.item_display,
    fr.profit_status,
    fr.net_profit_after_returns,
    fr.profit_rank,
    fr.latest_inventory_qty,
    fr.total_returns,
    fr.return_loss,
    fr.last_sale_date,
    fr.color_size_category,
    fr.total_qty_all_channels,
    CASE
        WHEN fr.net_profit_after_returns IS NULL THEN NULL
        WHEN fr.latest_inventory_qty = 0 THEN NULL
        ELSE fr.net_profit_after_returns / fr.latest_inventory_qty
    END AS profit_per_inventory_unit,
    CASE
        WHEN fr.net_profit_after_returns > 1000000 THEN 'VIP'
        WHEN fr.net_profit_after_returns < -500000 THEN 'HIGH_RISK'
        ELSE 'NORMAL'
    END AS risk_category
FROM final_report fr
WHERE fr.profit_rank <= 50

UNION ALL

SELECT
    NULL,
    'Aggregated Totals',
    NULL,
    SUM(fr.net_profit_after_returns),
    NULL,
    SUM(fr.latest_inventory_qty),
    SUM(fr.total_returns),
    SUM(fr.return_loss),
    NULL,
    NULL,
    SUM(fr.total_qty_all_channels),
    NULL,
    NULL
FROM final_report fr
WHERE fr.profit_rank <= 50
ORDER BY net_profit_after_returns DESC
