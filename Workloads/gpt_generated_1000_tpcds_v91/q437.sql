WITH catalog_agg AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS cnt_sales,
        MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '1998-01-01'
    GROUP BY i.i_item_sk, i.i_category
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
catalog_full AS (
    SELECT
        c.item_sk,
        c.category,
        c.total_net_profit,
        c.total_net_paid,
        i.total_quantity_on_hand,
        c.cnt_sales,
        'Catalog' AS channel
    FROM catalog_agg c
    FULL OUTER JOIN inventory_agg i ON c.item_sk = i.item_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr WHERE wr.wr_item_sk = c.item_sk
    )
),
web_agg AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid) AS total_net_paid,
        NULL AS total_quantity_on_hand,
        COUNT(*) AS cnt_sales,
        'Web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '1998-01-01'
    GROUP BY i.i_item_sk, i.i_category
),
combined AS (
    SELECT
        c.item_sk,
        c.category,
        c.total_net_profit,
        c.total_net_paid,
        c.total_quantity_on_hand,
        c.cnt_sales,
        c.channel
    FROM catalog_full c
    UNION ALL
    SELECT
        w.item_sk,
        w.category,
        w.total_net_profit,
        w.total_net_paid,
        w.total_quantity_on_hand,
        w.cnt_sales,
        w.channel
    FROM web_agg w
),
final AS (
    SELECT
        item_sk,
        category,
        channel,
        total_net_profit,
        total_net_paid,
        total_quantity_on_hand,
        cnt_sales,
        CASE WHEN total_net_paid > (SELECT AVG(total_net_paid) FROM combined) THEN 'High' ELSE 'Low' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS profit_rank,
        AVG(total_net_profit) OVER (PARTITION BY category) AS avg_profit_by_category
    FROM combined
)
SELECT
    item_sk,
    category,
    channel,
    total_net_profit,
    total_net_paid,
    total_quantity_on_hand,
    cnt_sales,
    sales_category,
    profit_rank,
    avg_profit_by_category
FROM final
WHERE profit_rank <= 100
ORDER BY total_net_profit DESC
LIMIT 100
