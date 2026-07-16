WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        d.d_year AS sales_year,
        ss.ss_net_profit AS profit,
        ca.ca_state AS state,
        i.i_brand AS brand,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        d.d_year AS sales_year,
        cs.cs_net_profit AS profit,
        ca.ca_state AS state,
        i.i_brand AS brand,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        d.d_year AS sales_year,
        ws.ws_net_profit AS profit,
        ca.ca_state AS state,
        i.i_brand AS brand,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
aggregated AS (
    SELECT
        state,
        sales_year,
        channel,
        brand,
        SUM(profit) AS total_profit,
        COUNT(*) AS transaction_count,
        approx_percentile(profit, 0.5) AS median_profit
    FROM sales_union
    GROUP BY state, sales_year, channel, brand
    HAVING SUM(profit) > 0
)
SELECT
    state,
    sales_year,
    channel,
    brand,
    total_profit,
    transaction_count,
    median_profit,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_profit DESC) AS profit_rank_by_year
FROM aggregated
ORDER BY sales_year, profit_rank_by_year, total_profit DESC
