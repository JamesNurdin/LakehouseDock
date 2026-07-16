WITH unified_sales AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        s.s_state AS region,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS profit,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state IS NOT NULL
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cc.cc_state AS region,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS profit,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state IS NOT NULL
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        wg.web_state AS region,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS profit,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN web_site wg ON ws.ws_web_site_sk = wg.web_site_sk
    WHERE wg.web_state IS NOT NULL
),
sales_with_date AS (
    SELECT
        us.channel,
        us.region,
        d.d_year,
        d.d_month_seq,
        us.item_sk,
        us.quantity,
        us.profit,
        us.net_paid
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
agg_sales AS (
    SELECT
        channel,
        region,
        d_year,
        d_month_seq,
        SUM(profit) AS total_profit,
        SUM(net_paid) AS total_net_paid,
        SUM(quantity) AS total_quantity,
        COUNT(*) AS txn_count,
        AVG(profit) AS avg_profit
    FROM sales_with_date
    GROUP BY channel, region, d_year, d_month_seq
)
SELECT
    channel,
    region,
    d_year,
    d_month_seq,
    total_profit,
    total_net_paid,
    total_quantity,
    txn_count,
    avg_profit,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS channel_profit_rank,
    SUM(total_profit) OVER (PARTITION BY d_year) AS yearly_total_profit,
    SUM(total_profit) OVER (PARTITION BY region) AS region_total_profit,
    SUM(total_profit) OVER (PARTITION BY d_year, d_month_seq) AS month_total_all_regions,
    SUM(total_profit) OVER (PARTITION BY region, d_year, d_month_seq) AS region_month_total,
    (total_profit / SUM(total_profit) OVER (PARTITION BY d_year)) * 100 AS pct_of_yearly_profit,
    (total_profit / SUM(total_profit) OVER (PARTITION BY region)) * 100 AS pct_of_region_profit,
    (total_profit / SUM(total_profit) OVER (PARTITION BY d_year, d_month_seq)) * 100 AS pct_of_month_total,
    (total_profit / SUM(total_profit) OVER (PARTITION BY region, d_year, d_month_seq)) * 100 AS pct_of_region_month_total,
    LAG(total_profit) OVER (PARTITION BY channel, region ORDER BY d_year, d_month_seq) AS prev_month_profit,
    CASE
        WHEN LAG(total_profit) OVER (PARTITION BY channel, region ORDER BY d_year, d_month_seq) IS NOT NULL
        THEN (total_profit - LAG(total_profit) OVER (PARTITION BY channel, region ORDER BY d_year, d_month_seq))
             / LAG(total_profit) OVER (PARTITION BY channel, region ORDER BY d_year, d_month_seq) * 100
    END AS mom_growth_pct,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM agg_sales
WHERE total_profit > 0
ORDER BY d_year, d_month_seq, channel, total_profit DESC
LIMIT 500
