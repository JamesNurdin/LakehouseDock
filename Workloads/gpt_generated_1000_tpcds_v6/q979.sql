/*
Goal: Produce a combined view of daily net paid sales for the year 2001 across catalog and web channels, broken down by household demographic. For each day and demographic we show the total net paid, categorize profit level, count of active promotions, and indicate the sales channel. The results from catalog_sales and web_sales are unified with UNION ALL, distinct rows are kept, and the output is ordered by highest net paid.
*/
WITH catalog_agg AS (
    SELECT
        d.d_date,
        hd.hd_demo_sk,
        'Catalog' AS sales_channel,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        (
            SELECT COUNT(DISTINCT p2.p_promo_id)
            FROM promotion p2
            WHERE p2.p_start_date_sk <= d.d_date_sk
              AND p2.p_end_date_sk   >= d.d_date_sk
        ) AS active_promo_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, hd.hd_demo_sk, d.d_date_sk
),
web_agg AS (
    SELECT
        d.d_date,
        hd.hd_demo_sk,
        'Web' AS sales_channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        (
            SELECT COUNT(DISTINCT p2.p_promo_id)
            FROM promotion p2
            WHERE p2.p_start_date_sk <= d.d_date_sk
              AND p2.p_end_date_sk   >= d.d_date_sk
        ) AS active_promo_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, hd.hd_demo_sk, d.d_date_sk
)
SELECT DISTINCT
    agg.d_date,
    agg.hd_demo_sk,
    agg.sales_channel,
    agg.total_net_paid,
    agg.profit_category,
    agg.active_promo_count
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) AS agg
ORDER BY agg.total_net_paid DESC, agg.d_date ASC
LIMIT 100
