WITH catalog AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
),
web AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
)
SELECT
    channel,
    i_category,
    i_brand,
    d_year,
    d_month_seq,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_sales,
    SUM(net_profit) AS total_profit,
    CASE WHEN SUM(net_paid) = 0 THEN 0 ELSE SUM(net_profit) / SUM(net_paid) END AS profit_margin
FROM (
    SELECT
        'Catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.d_year,
        cs.d_month_seq,
        cs.i_category,
        cs.i_brand
    FROM catalog cs
    UNION ALL
    SELECT
        'Web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.d_year,
        ws.d_month_seq,
        ws.i_category,
        ws.i_brand
    FROM web ws
) t
GROUP BY channel, i_category, i_brand, d_year, d_month_seq
ORDER BY channel, i_category, i_brand, d_year, d_month_seq
