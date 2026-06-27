WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),

sales_agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        sum(net_profit) AS total_net_profit,
        sum(quantity) AS total_quantity
    FROM sales
    GROUP BY d_year, d_month_seq, i_category
),

inventory_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        avg(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_net_profit,
    s.total_quantity,
    i.avg_inventory_on_hand,
    CASE WHEN i.avg_inventory_on_hand > 0 THEN s.total_net_profit / i.avg_inventory_on_hand END AS profit_per_inventory_unit
FROM sales_agg s
LEFT JOIN inventory_month i
    ON s.d_year = i.d_year
   AND s.d_month_seq = i.d_month_seq
   AND s.i_category = i.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
